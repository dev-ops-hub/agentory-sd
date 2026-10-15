#!/usr/bin/env bash
# Enforces that sprintkit's product-auditor runs after any PRD or sprint-spec edit.
#   dirty    PostToolUse Write|Edit : a PRD or spec file was changed -> mark that kind dirty
#   reviewed PostToolUse Agent      : product-auditor was dispatched -> mark the audited kind reviewed
#                                     ("Spec mode" in the brief = specs, otherwise = PRD)
#   check    Stop                   : block the stop if a kind is dirty and newer than its review
# State lives per session in $TMPDIR so nothing is left in the repo.
set -u
# Without jq every check silently passes, so say so loudly (exit 1 = non-blocking error shown to the user).
command -v jq >/dev/null 2>&1 || { echo "prd-review-gate.sh: jq not found, so this hook is NOT enforcing anything. Install jq (macOS: brew install jq; Windows: winget install jqlang.jq; Debian/Ubuntu: apt install jq)." >&2; exit 1; }
mode="${1:-}"
input="$(cat)"
sid="$(jq -r '.session_id // "nosession"' <<<"$input")"
dir="${TMPDIR:-/tmp}/sprintkit-prd-gate"
mkdir -p "$dir"

case "$mode" in
  dirty)
    path="$(jq -r '.tool_input.file_path // ""' <<<"$input")"
    path="${path//\\//}"   # Windows: C:\repo\planning\x.md -> C:/repo/planning/x.md
    case "$path" in
      */planning/product-req-document\(PRD\).md|*/planning/*-product-req-document\(PRD\).md) touch "$dir/$sid.prd.dirty" ;;
      */planning/specs/*.md) touch "$dir/$sid.spec.dirty" ;;
    esac
    ;;
  reviewed)
    [ "$(jq -r '.tool_input.subagent_type // ""' <<<"$input")" = "product-auditor" ] || exit 0
    if jq -r '.tool_input.prompt // ""' <<<"$input" | grep -q 'Spec mode'; then
      touch "$dir/$sid.spec.reviewed"
    else
      touch "$dir/$sid.prd.reviewed"
    fi
    ;;
  check)
    # Already blocked once this turn: let it stop rather than loop forever.
    [ "$(jq -r '.stop_hook_active // false' <<<"$input")" = "true" ] && exit 0
    stale() { [ -e "$dir/$sid.$1.dirty" ] && { [ ! -e "$dir/$sid.$1.reviewed" ] || [ "$dir/$sid.$1.dirty" -nt "$dir/$sid.$1.reviewed" ]; }; }
    reasons=()
    stale prd && reasons+=("The PRD was edited but product-auditor has not audited the current version. Run the product audit loop from sprintkit-start (\"After generating the PRD: product audit\"): dispatch product-auditor in PRD mode, relay AUTHOR findings to product-manager, ask the user the USER ones, and re-audit. Stop after PASS or 3 rounds.")
    stale spec && reasons+=("A sprint spec under planning/specs/ was edited but product-auditor has not audited it since. Run sprintkit-plan Step 12: dispatch product-auditor in Spec mode, relay AUTHOR findings to technical-product-manager (Revise mode), ask the user the USER ones, and re-audit. Stop after PASS or 3 rounds.")
    [ ${#reasons[@]} -eq 0 ] && exit 0
    jq -n --arg r "$(printf '%s\n' "${reasons[@]}")" '{decision:"block", reason:$r}'
    ;;
esac
exit 0
