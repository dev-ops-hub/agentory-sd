#!/usr/bin/env bash
# Keeps the sprintkit session file (.claude/sprintkit/SESSION.md) saved on every pause or stop.
#   prompt  UserPromptSubmit    : mark turn start, clear the previous turn's active flag, mark sprintkit active if the prompt names a sprintkit skill
#                                 or an active session has uncommitted tracked planning changes
#   skill   PostToolUse Skill   : mark sprintkit active if a sprintkit-* skill was invoked
#   check   Stop                : block once if an active session file was not updated this turn,
#                                 then commit and push each session file changed this turn
#                                 (never on main/master or the remote default branch)
# Markers live per session in $TMPDIR so nothing is left in the repo.
set -u
# Without jq every check silently passes, so say so loudly (exit 1 = non-blocking error shown to the user).
command -v jq >/dev/null 2>&1 || { echo "sprintkit-session.sh: jq not found, so this hook is NOT enforcing anything. Install jq (macOS: brew install jq; Windows: winget install jqlang.jq; Debian/Ubuntu: apt install jq)." >&2; exit 1; }
mode="${1:-}"
input="$(cat)"
sid="$(jq -r '.session_id // "nosession"' <<<"$input")"
dir="${TMPDIR:-/tmp}/sprintkit-session"
mkdir -p "$dir"
turn="$dir/$sid.turn"
active="$dir/$sid.active"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
root="${root//\\//}"   # Windows: backslashes -> forward slashes (Git Bash accepts C:/...)

case "$mode" in
  prompt)
    date +%s >"$turn"
    rm -f "$active"   # per turn: only a turn that names or runs a sprintkit skill is checked
    jq -r '.prompt // ""' <<<"$input" | grep -q 'sprintkit-' && touch "$active"
    # A plain follow-up ("continue") is still checked while a session file says Status: active
    # and tracked planning files (not the session files) have uncommitted changes.
    if [ ! -e "$active" ] && cd "$root" 2>/dev/null; then
      for f in planning/session.md planning/*-session.md; do
        [ -f "$f" ] && grep -q '^\*\*Status:\*\* active' "$f" && {
          git diff --quiet HEAD -- planning ':(exclude)planning/session.md' ':(exclude)planning/*-session.md' 2>/dev/null || touch "$active"
          break
        }
      done
    fi
    ;;
  skill)
    jq -r '.tool_input.skill // ""' <<<"$input" | grep -q '^sprintkit-' && touch "$active"
    ;;
  check)
    [ -e "$active" ] || exit 0
    cd "$root" || exit 0
    shopt -s nullglob
    files=(planning/session.md planning/*-session.md)
    [ ${#files[@]} -gt 0 ] || exit 0

    mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"; }
    since="$(cat "$turn" 2>/dev/null || echo 0)"
    changed=()
    stale_active=0
    for f in "${files[@]}"; do
      [ -f "$f" ] || continue
      if [ "$(mtime "$f")" -ge "$since" ] && [ "$since" -gt 0 ]; then
        changed+=("$f")
      elif grep -q '^\*\*Status:\*\* active' "$f"; then
        stale_active=1
      fi
    done

    # Nothing updated this turn while a session is active: block once (not again on the retry).
    if [ ${#changed[@]} -eq 0 ] && [ "$stale_active" = 1 ] &&
       [ "$(jq -r '.stop_hook_active // false' <<<"$input")" != "true" ]; then
      jq -n '{decision:"block", reason:"A sprintkit session is active but its session file was not updated this turn. Before stopping, update planning/<track>-session.md (or planning/session.md) per .claude/sprintkit/SESSION.md: Step, In progress (facts gathered, confirmed drafts, the exact question waiting), Updated, and Resume with. If nothing changed since the last save, refresh Updated only."}'
      exit 0
    fi

    branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null)" || exit 0
    default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
    default="${default#origin/}"
    case "$branch" in main|master|"$default") exit 0 ;; esac
    committed=0
    for f in ${changed[@]+"${changed[@]}"}; do
      git add -- "$f" 2>/dev/null || continue
      git diff --cached --quiet -- "$f" && continue
      git commit -q -m "chore(sprintkit): save $f" -- "$f" >/dev/null 2>&1 && committed=1
    done
    if [ "$committed" = 1 ]; then
      if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
        nohup git push -q >/dev/null 2>&1 &
      else
        nohup git push -q -u origin "$branch" >/dev/null 2>&1 &
      fi
    fi
    ;;
esac
exit 0
