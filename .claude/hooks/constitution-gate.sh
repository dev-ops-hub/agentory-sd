#!/usr/bin/env bash
# PreToolUse Agent|Task: while planning/constitution.md exists, block any subagent dispatch
# whose brief does not mention constitution.md (see .claude/sprintkit/CONSTITUTION.md).
set -u
# Without jq every check silently passes, so say so loudly (exit 1 = non-blocking error shown to the user).
command -v jq >/dev/null 2>&1 || { echo "constitution-gate.sh: jq not found, so this hook is NOT enforcing anything. Install jq (macOS: brew install jq; Windows: winget install jqlang.jq; Debian/Ubuntu: apt install jq)." >&2; exit 1; }
input="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
root="${root//\\//}"   # Windows: backslashes -> forward slashes (Git Bash accepts C:/...)
[ -f "$root/planning/constitution.md" ] || exit 0

case "$(jq -r '.tool_input.subagent_type // ""' <<<"$input")" in
  Explore|claude-code-guide|statusline-setup) exit 0 ;;
esac

jq -r '.tool_input.prompt // ""' <<<"$input" | grep -q 'constitution\.md' && exit 0

jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny",
  permissionDecisionReason:"This project has a constitution (planning/constitution.md). Add the brief line from .claude/sprintkit/CONSTITUTION.md to the agent prompt, then dispatch again: \"Read `planning/constitution.md` before anything else. Its MUST rules override this brief; if the task conflicts with one, stop and report the conflict instead of working around it. Start your result with `Constitution: v<version> read`.\""}}'
exit 0
