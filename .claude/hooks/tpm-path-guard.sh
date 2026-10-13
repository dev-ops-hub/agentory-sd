#!/usr/bin/env bash
# PreToolUse Write|Edit, scoped to the technical-product-manager agent (agent frontmatter hook):
# the agent may create or edit only sprint spec files, planning/specs/*.md (default track
# planning/specs/sprint-<N>.md, named track planning/specs/<name>-sprint-<N>.md). Anything else is denied.
set -u
# Without jq every check silently passes, so say so loudly (exit 1 = non-blocking error shown to the user).
command -v jq >/dev/null 2>&1 || { echo "tpm-path-guard.sh: jq not found, so this hook is NOT enforcing anything. Install jq (macOS: brew install jq; Windows: winget install jqlang.jq; Debian/Ubuntu: apt install jq)." >&2; exit 1; }
input="$(cat)"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
root="${root//\\//}"
root="${root%/}"
path="$(jq -r '.tool_input.file_path // ""' <<<"$input")"
path="${path//\\//}"

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}'
  exit 0
}

[ -n "$path" ] || deny "tpm-path-guard: no file_path in the tool call."
case "$path" in
  *"/../"*|*"/.."|"../"*) deny "tpm-path-guard: '..' is not allowed in the path. Write only planning/specs/sprint-<N>.md." ;;
esac
case "$path" in
  /*|[A-Za-z]:/*) ;;                 # absolute
  *) path="$root/$path" ;;           # relative to the project root
esac
case "$path" in
  "$root"/planning/specs/*.md) exit 0 ;;
esac
deny "tpm-path-guard: the technical-product-manager agent may only create or edit planning/specs/*.md (its assigned spec file). Refused: $path"
