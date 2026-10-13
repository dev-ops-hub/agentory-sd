# Jira/Confluence sync rules

**The rule:** when Jira and/or Confluence is configured, it is the source of truth for whatever it can represent; the local markdown is pulled into line with it before implementation starts. When neither is configured, the local markdown is the only source of truth and this file does not apply — behavior is unchanged from before this file existed.

This is the read-back half of `sprintkit-jira`, which only ever pushes (local → Jira/Confluence, one way). This file governs the opposite direction: Jira/Confluence → local, run by `sprintkit-implement` and `sprintkit-autopilot` before they build anything.

## Why this can't cover everything

Jira issues and Confluence pages don't carry everything the local markdown does:

| Carries | Jira | Confluence | Local only |
|---|---|---|---|
| Story title, description, status, priority, labels | yes | — | — |
| Dependency between sprints | yes, as an issue link | — | — |
| A sprint's full spec (FR/NFR tables, Given/When/Then ACs, TC test oracles) | no | yes, as a published page (only if `confluence.documents` includes `specs`) | fallback if not published |
| `**Touches:**` (file-scope guard) | no | no | **always** — there is no remote field for this, enabled or not |
| The sprint plan as a whole (headings, every sprint's goal/stories/deps in one document) | no | yes, as a published page | fallback if not published |
| PRD / constitution | no | yes, as published pages | fallback if not published |

So "Jira/Confluence is the source of truth" means: for the rows above that have a `yes`, remote wins. For `**Touches:**`, local always wins, configured or not — pulling it from nowhere isn't possible. For the two whole-document rows (sprint plan, PRD/constitution), remote is **detected, never auto-applied** — see "Detect-and-warn" below.

## Configured or not

Same test as `sprintkit-jira`'s "Configured or not" section: read `agent-config/jira_confluence.json` (or the legacy `agent-config/jira.json` for Jira only), ignoring `_`-prefixed keys. Jira configured needs `jira.enabled: true` plus `site` and `jira.project-prefix`. Confluence configured needs `confluence.enabled: true` plus `site` and `confluence.space-key`. Judge each independently; run the sync for whichever is configured, skip the other.

If neither is configured, skip this whole file silently — do not mention it, do not look for the Atlassian MCP.

## When this runs

- **`sprintkit-implement` (standalone, one process, one branch):** once, right after Track Resolution and before Step 1, on the stories and spec of the sprint being implemented. Any pulled change is written straight into the working tree and rides along as part of the sprint's normal commits — no separate sync commit.
- **`sprintkit-autopilot`:** once, in pre-flight, on the base branch (`main` or `epic/<track>`), covering every story and spec of every sprint currently eligible to be scheduled (not the whole backlog — only what might be dispatched this run). Do this **before** computing the ready queue or dispatching any runner, so every runner reads already-synced files. If anything changed, commit it directly as its own small commit (`chore(<track>): sync planning files from Jira/Confluence`) before DISPATCH, following the file's existing push rules (never force-push). Runners themselves make no Jira/Confluence calls and need no knowledge of this file — keeping the sync single-writer avoids N concurrent worktrees racing to edit the same `sprint_file`.
- **`sprintkit-loop`:** nothing extra — it delegates to `sprintkit-implement`, which already covers it.
- Never run mid-sprint, only before the sprint's work starts. Jira/Confluence edits that land after that point are picked up on the *next* implement/autopilot run, not this one — document this as a known limitation if it comes up, don't pretend otherwise.

## Preflight (same as sprintkit-jira)

Find the Atlassian MCP tools (`ToolSearch` for `atlassian jira`). If configured but not connected, stop and tell the user to connect it — do not fall back to local silently, because that would quietly violate the "remote is truth when configured" rule. Confirm the connected site matches `site`.

## What to pull, per sprint in scope

Use `planning/scratchpad/jira-mapping.json` (or `<name>-jira-mapping.json`) to resolve IDs; a story/sprint with no mapping entry has never been exported, so nothing to pull — skip it, not an error.

1. **Stories.** For each story ID in scope, `getJiraIssue` on its mapped key. Compare `fields.updated` to the mapping's `syncState.stories.<id>.updated` (add this field if absent — treat a missing value as "never synced," i.e. always pull once to establish a baseline). If the issue is newer:
   - Overwrite the story's title line and its "As a / I want / so that" statement in the Sprint file with the issue's summary/description.
   - Update the story's status in the session file / implementation notes' `todo -> in-progress -> in-review -> done` tracker to match the issue's Jira status (map Jira's workflow names to these four as sensibly as the project's workflow allows; log the mapping you used).
   - Write the issue's `fields.updated` into `syncState.stories.<id>.updated`.
   - Record what changed in `planning/scratchpad/jira-comments.md` as a sync note (not a decision — just a transparency log: "pulled from TS-14: title changed, status todo -> in-progress").

2. **Dependencies.** For each story's issue, read its issue links (`listJiraIssueRemoteIssueLinks`/the issue's own `issuelinks` field — `discover` the right read operation if neither is a primary tool). For each "is blocked by" link, map the linked issue key back to a sprint via the mapping's reverse lookup (`stories`/`epics` values → keys → which sprint owns that story). Reconstruct the resulting sprint dependency set; if it differs from the sprint's `**Dependencies:**` line, overwrite that line. A linked issue that can't be mapped back to a known sprint is left out and logged — never guessed.

3. **Spec content.** If `confluence.documents` includes `specs` and the mapping has `confluence["specs/sprint-<N>"]`, `getConfluenceContent` on that `pageId`. Compare its `version.number` to `syncState.confluence["specs/sprint-<N>"].version` (missing = never synced, pull once). If the page is newer:
   - Convert the page body back to the spec's markdown structure as closely as possible (sections, FR/NFR/AC/TC tables) and overwrite `planning/specs/sprint-<N>.md`.
   - **Safety valve:** immediately re-run `python3 .claude/agents/technical-product-manager/skills/tracing-spec-coverage/scripts/check_spec.py <spec> --plan <Sprint file> --sprint <N>`. If it fails, STOP — report the failure and the page URL, and do not implement against a spec that no longer parses. This is a structural check, not a "which side wins" question; remote still won, it just turned out to be broken, and that gets reported rather than silently implemented against.
   - Write the new version number into `syncState.confluence["specs/sprint-<N>"].version`.
   - Log the change in `planning/scratchpad/jira-comments.md` the same way as a story pull.

## Detect-and-warn only (never auto-applied)

For the whole-document pages — `sprint-plan` (the full Sprint file), `prd`, `constitution` — compare their Confluence `version.number` to the mapping's stored value the same way, but **do not overwrite anything** if it changed. These are free-form documents spanning many sprints; blindly regenerating `planning/sprint.md` or the PRD from a Confluence page risks corrupting every sprint's `**Dependencies:**`/`**Touches:**`/status markers at once, not just the one in scope. Instead: tell the user the page was edited after the last publish and that reconciling it properly means running `sprintkit-start` (PRD/constitution) or `sprintkit-plan` (sprint plan) by hand, not an automatic pull. Do not stop the build for this — it's a warning, not a blocker, unless the edited section is one this sprint actually depends on, in which case treat it like any other open conflict and stop.

## What never syncs from remote, configured or not

`**Touches:**` lines. There is no Jira field and no Confluence structure for them — they are a sprintkit-only scheduling device. Always read from local.

## The tradeoff this rule accepts

"Remote wins when configured" is unconditional — there is no per-conflict prompt. If a local edit to a story, a dependency, or a spec was made since the last `sprintkit-jira` export and never pushed, this sync will overwrite it, because the rule treats remote as authoritative, full stop. The way to protect a deliberate local change is to run `sprintkit-jira` first (pushing it to Jira/Confluence) before the next implement or autopilot run pulls it back down. State this plainly in the sync's report line so it is never a silent surprise after the fact, even though it is never a blocking question before the fact.
