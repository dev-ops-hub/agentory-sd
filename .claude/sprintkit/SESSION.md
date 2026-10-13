# Sprintkit session file

A Claude Code conversation lives on one machine and does not travel with `git clone`. The session file is what travels: one per track, committed and pushed on every pause or stop, so whoever checks out the track branch next (`git switch sprintkit/<track>`) can continue where the last person stopped, mid-interview or mid-build.

Every `sprintkit-*` skill follows this protocol.

## Path

| Track | Session file |
|---|---|
| `default` | `planning/session.md` |
| `<name>` | `planning/<name>-session.md` |

## 0. Work on the track branch

Sprintkit never commits to the default branch (`main`/`master`). Planning work (PRD, constitution, sprint plan, sprint graph) and the session file live on the track branch `sprintkit/<track>` (`sprintkit/default` for the default track) and reach `main` through a merge request.

Right after track resolution:

1. `git fetch origin` (skip if there is no remote).
2. If the current branch is `main`/`master` or detached, switch to the track branch: `git switch sprintkit/<track>` if it exists locally, else `git switch -c sprintkit/<track> --track origin/sprintkit/<track>` if it exists on origin, else `git switch -c sprintkit/<track>` from the current `main`. Uncommitted changes come along. Tell the user in one line.
3. If already on another non-default branch, stay on it and record it as **Branch** in the session file; that branch is the track branch for this session.

Exceptions: `sprintkit-autopilot` manages its own branches during Build (`main` or `epic/<track>` as the base, one branch per sprint), and autopilot runners work in their own worktrees. Neither switches to the track branch.

## 1. Read it first

Right after track resolution, before any other work (before interviewing, planning, reading the sprint plan or dispatching agents):

1. If the session file exists, read it.
2. If `**Status:** active`:
   - **Same skill as `**Active skill:**`** — resume from `**Step:**` and the **In progress** section. Tell the user in one line where you are picking up (who left it, when, which step). Do not re-ask questions already answered there; re-ask only the pending question it records.
   - **Different skill** — tell the user which skill and step is in progress and show its **Resume with** command. Continue with the current skill only if the user says so.
3. If the files on disk (PRD, constitution, sprint file) disagree with the session file, the files win. Note the mismatch in History.
4. If there is no session file, create it from the template once the track is resolved.

## 2. Write it before every pause or stop

Update the session file **before ending any turn**: every question to the user, every approval request, every stop on an error or blocker, and when a skill finishes. Also update it after each milestone (agent draft folded in, auditor round, constitution written, sprint merged).

- Rewrite **In progress** completely each time. For an unfinished conversation it is the only record: the facts the user gave, drafts they confirmed, and the exact question now waiting for an answer.
- Append one line to **History** per milestone, not per turn.
- Keep it under about 80 lines. Do not copy the PRD, constitution or sprint plan into it; point at them.
- Never write secrets, tokens or credentials into it.
- Set `**Status:** complete` only when nothing is left in progress for this track (PRD approved with no pipeline running, pipeline final summary, retro done). Otherwise keep it `active` and point **Resume with** at the next step.
- Only the orchestrating session writes it. Subagents (product-manager, product-auditor, autopilot runners) never do.

## 3. Saving to git

The `sprintkit-session` Stop hook ([.claude/hooks/sprintkit-session.sh](../hooks/sprintkit-session.sh)) does this, so skills do not commit the session file themselves:

- If a sprintkit skill ran this session and an active session file was not updated during the turn, the stop is blocked once with a reminder to update it.
- Each session file changed during the turn is committed on its own (`chore(sprintkit): save <file>`) and pushed to the current branch in the background. Nothing else that is staged is included.
- On `main`/`master` or a detached HEAD it never commits or pushes; the change stays in the working tree until the next save on a track branch.
- A failed push leaves the local commit in place; the next successful save pushes it.

`sprintkit-pipeline` still commits stage artifacts together with the session file at each stage checkpoint.

## Template

```markdown
# Sprintkit session: <track>

**Status:** active
**Updated:** <YYYY-MM-DD HH:MM TZ>  **By:** <git user.name>  **Branch:** <sprintkit/<track> or the branch in use>
**Active skill:** <sprintkit-start | sprintkit-pipeline | ...>  **Step:** <e.g. interview, audit round 2, constitution, sprint 3 review cycle 2>
**Resume with:** `/<skill> track:<track> [args]`

## Where things stand
<2-4 lines: files that exist, sprints done of total, what is blocked, PR/MR links>

## In progress
<What the next person needs to continue the current step:>
- Facts gathered: <user answers so far, short and attributed>
- Confirmed drafts: <which PRD sections are agreed, and where they live if not yet in the PRD>
- Waiting on: <the exact question or approval pending, verbatim> | nothing

## Decisions made (not obvious from the files)
- <decision and why>

## Open questions / blockers
- <question or blocker> | none

## History
- <YYYY-MM-DD> <by>: <skill> <step>: <one-line outcome>
```
