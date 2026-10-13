---
name: sprintkit-pipeline
description: End-to-end driver for the whole sprintkit flow — PRD interview, sprint plan, dependency graph check, autopilot build, and retro — chained so the user does not have to invoke each stage by hand. Detects what already exists (PRD, sprint plan, partly built sprints) and resumes from the right stage. Use when the user says "run the whole pipeline", "idea to shipped", "take this from PRD to done", "do the full flow", "automate the whole thing", "start to finish", "sprintkit pipeline", or wants one command that covers PRD, plan and build. Not for running a single stage on its own — use that stage's skill directly.
---

# Sprintkit Pipeline

You are a **stage controller**. You run the sprintkit stages in order, deciding where to start from what already exists on disk, and hand each stage to the skill that owns it. You do not write PRDs, plans or code yourself.

```
sprintkit-start → sprintkit-plan → sprintkit-graph → sprintkit-autopilot → sprintkit-retro
   (PRD + constitution, human)  (sprints)        (audit, gate)       (build + merge)       (memory)
```

## Args

Pass-through, all optional: `track:<name>`, `epic`, `runners:N`. Anything else the user says is treated as the feature description for the PRD stage. Forward `track:` to every stage; forward `epic` and `runners:` to autopilot only.

## Track resolution

Resolve the track once, using the same rules as the other sprintkit skills:

- `track:<name>` in args → `planning/<name>-product-req-document(PRD).md` + `planning/<name>-sprint.md`; `track:default` → `planning/product-req-document(PRD).md` + `planning/sprint.md`.
- Otherwise scan `planning/` for `*-product-req-document(PRD).md` / `product-req-document(PRD).md`. One track → use it. Several → ask which. None → ask whether this is the default track or a named one (suggest a short lowercase slug), then use that.

Store `track`, `prd_file`, `sprint_file` for the session, and `session_file`: `planning/session.md` for the default track, otherwise `planning/<name>-session.md`. The session file follows [.claude/sprintkit/SESSION.md](../../sprintkit/SESSION.md), which every sprintkit skill reads first and updates before every pause or stop.

Then switch to the track branch per section 0 of that protocol: planning stages run on `sprintkit/<track>` (store it as `track_branch`), never on `main`.

## Stage detection

If `session_file` exists, read it first: it records the active skill and step, what was in progress, decisions and open questions from earlier sessions, possibly by another person on another machine. Tell the user in one line what it says (who, when, which step), then confirm against the files below. **The files win** if the two disagree, since the session file may be stale; note the mismatch in its History. If it shows a stage skill mid-step (for example `sprintkit-start` at `interview`), start at that stage; the stage skill resumes from the session file itself.

Check the files, then start at the first row that matches:

| State on disk | Start at |
|---|---|
| No PRD file | **1. PRD** |
| PRD exists, no `planning/constitution.md` | **1b. Constitution** |
| PRD exists, no sprint file | **2. Plan** |
| Sprint file exists, at least one sprint not `[DONE]`, planning files not yet on `origin/main` | **3. Graph** |
| Sprint file exists, at least one sprint not `[DONE]`, planning files on `origin/main` | **4. Build** |
| Sprint file exists, every sprint `[DONE]` | **5. Retro** |

State the detected starting stage in one line, then create a TodoWrite list with one todo per remaining stage (`PRD`, `Constitution`, `Plan`, `Graph check`, `Planning MR`, `Build`, `Retro`, skipping stages already satisfied). The todo list is the forcing function: while any stage todo is pending, you are not finished.

If the user asked to revise an existing PRD, start at **1. PRD** regardless.

## Stages

### 1. PRD — human in the loop

Invoke `sprintkit-start` via the Skill tool with `args: "track:<track>"`, passing along the user's feature description if they gave one.

This stage is conversational by design and cannot be automated away: the interview and the review loop need the user. Let it run until the user approves the PRD. Do not continue on your own judgement that the PRD "looks fine" — approval means the user said so. `sprintkit-start` drafts the project constitution itself once the product-auditor passes the PRD, so the user reviews both together.

→ Mark the `PRD` todo `completed`. If `planning/constitution.md` now exists, mark `Constitution` completed too and go to **2. Plan**; otherwise go to **1b. Constitution**.

### 1b. Constitution — human in the loop

Invoke `sprintkit-start` via the Skill tool with `args: "track:<track> constitution"`. It skips the interview and has the `product-manager` agent draft `planning/constitution.md` from the PRD without asking the user; unresolved points are left as `TODO` lines.

→ Verify `planning/constitution.md` exists. Mark the todo `completed`, go to **2. Plan**.

### 2. Plan

Invoke `sprintkit-plan` via the Skill tool with `args: "track:<track>"`. If it asks the user a question, relay it and resume; if it produces a long report, do not stop on it.

→ Verify `sprint_file` now exists and contains sprint headings, and that every `**Spec:**` line that names a file points at one that exists (`not written yet` is allowed when the user chose to spec only some sprints). If not, STOP and report. Otherwise go to **3. Graph**.

### 3. Graph check — the one automatic gate

Invoke `sprintkit-graph` via the Skill tool with `args: "track:<track>"`. It is read-only and writes `planning/sprint-graph.md`. `sprintkit-plan` also hands off to the graph on its own when it ends with every spec audited `PASS`; here, the pipeline owns the call, so run it once.

| Graph result | Action |
|---|---|
| Clean, or only advisory notes (e.g. some accidental serialisation) | Show the user a 3-line summary — sprint count, max parallel width, critical path — then go to **3b. Planning MR** without asking. |
| Dependency cycle, or a sprint depending on a sprint that does not exist | STOP. Show the finding and ask the user whether to re-run `sprintkit-plan` or edit the sprint file by hand. Do not start the build. |

Cycles and phantom dependencies make autopilot deadlock, so catching them here is cheaper than finding them mid-build. Anything softer is the user's call to fix later; it does not block.

### 3b. Planning MR — human gate before code

Autopilot builds from `main` (or from `epic/<track>`, which is cut from `main`), so the planning files must be merged before Build can start. "On `origin/main`" means `git fetch origin` then `git cat-file -e origin/main:<sprint_file>` succeeds and `git diff --quiet origin/main <track_branch> -- <prd_file> planning/constitution.md <sprint_file> planning/specs/` shows no difference. The session file is left out: it changes every turn and is not needed for the build.

1. If the planning files are already on `origin/main`, mark the todo `completed` and go to **4. Build**.
2. Otherwise push `track_branch` and open a PR/MR into `main` if none is open, using the **open a PR/MR** command for the host resolved per [.claude/sprintkit/GIT-HOST.md](../../sprintkit/GIT-HOST.md) (`glab mr create` or `gh pr create`). Title `sprintkit(<track>): PRD, constitution, sprint plan and specs`; the body lists the files, the graph summary, and the spec coverage and audit verdict lines.
3. STOP. Show the MR link and tell the user to review and merge it, then re-run `/sprintkit-pipeline track:<track>` to start the build. Set the session file's **Step** to `planning MR` and **Waiting on** to the MR link.

Never merge the planning MR yourself.

### 4. Build

Invoke `sprintkit-autopilot` via the Skill tool with `args: "track:<track> [epic] [runners:N]"`, forwarding only the flags the user supplied.

Autopilot owns scheduling, review loops, merging and plan sync. Do not add your own commentary between its steps, and do not re-implement any of it.

When it returns:

| Autopilot ended with | Action |
|---|---|
| COMPLETE (every sprint `[DONE]`) | → **5. Retro** |
| COMPLETE but some subtrees blocked | Skip retro. Show its blocked-sprint table and tell the user to fix them and re-run the pipeline; it will resume at this stage. |
| Paused (CRITICAL_STOP) | Relay its reason and "what needs to happen". Stop. Re-running the pipeline resumes here via stage detection. |

In epic mode, autopilot leaves the epic→main PR open. Surface its URL as the final step; never merge it.

### 5. Retro

Invoke `sprintkit-retro` via the Skill tool. It proposes memory entries and writes them only after the user confirms, so this stage ends with a confirmation prompt by design.

## Session file — saving the session for the next person

A Claude Code conversation lives on one machine and does not travel with `git clone`, so it cannot be handed over. What can travel is the repo. Stage skills keep `session_file` current on every pause or stop, and the `sprintkit-session` Stop hook commits and pushes it. On top of that, after every stage, write a checkpoint to `session_file` and commit it with that stage's artifacts, so the next person (or the same person on another machine) runs the pipeline and picks up where it stopped.

**Checkpoint, run after each stage ends (also when it ends stopped or blocked):**

1. Update `session_file` using the template in [.claude/sprintkit/SESSION.md](../../sprintkit/SESSION.md): set **Active skill** to `sprintkit-pipeline`, **Step** to the next stage, **Resume with** to `/sprintkit-pipeline track:<track> [epic] [runners:N]`, and append one line to History.
2. Stage only the files this stage produced plus the session file, by name:

   | Stage | Files |
   |---|---|
   | PRD | `prd_file`, `planning/constitution.md`, `session_file` |
   | Constitution | `planning/constitution.md`, `session_file` |
   | Plan | `sprint_file`, `planning/specs/`, `session_file` |
   | Graph | `planning/sprint-graph.md`, `session_file` |
   | Build | `session_file` only (autopilot has already merged the code and synced `sprint_file` on its base branch) |
   | Retro | `session_file` |

   Never `git add -A`. If a named file has no changes, skip it.
3. Commit: `chore(<track>): session after <stage> stage`.
4. Commit and push only on `track_branch`, never on `main`/`master`. Planning stages (PRD to Planning MR) already run there. After **Build** or **Retro**, autopilot has left you on `main` or `epic/<track>`: `git fetch origin`, then `git switch sprintkit/<track>` and `git merge --ff-only origin/main` if that succeeds, otherwise `git switch -C sprintkit/<track> origin/main` (the planning MR is merged, so nothing is lost). Your modified session file comes along. Commit there, push with `-u origin sprintkit/<track>` if it has no upstream, and open or update an MR into `main` so the final session state lands. Never force-push.
5. If the push fails (no remote, no auth, non-fast-forward), do not retry destructively. Keep the local commit, add "Not pushed: <reason>" to the stage summary, and continue. Share the branch yourself if that matters.

Do the checkpoint even when a stage stopped early; a blocked sprint or an unanswered question is exactly what the next person needs to know.

Only record what the files do not already say. Do not copy the PRD or the sprint plan into it.

**Not shared by this mechanism:** the conversation itself, and `sprintkit-retro`'s memory entries, which live under the user's local `~/.claude/projects/` memory directory. If a retro lesson should reach the next person, add it to Decisions in the session file. At the final summary, set **Status** to `complete` if nothing is left in progress.

## Mandatory transition

After each stage skill returns and its checkpoint is committed, your next action is `TodoWrite` (mark that stage `completed`) followed immediately by the next stage's tool call, with no freestanding prose in between. Stage skills end on long, conclusive-looking reports, and that closing feel is what makes a controller stop one stage early. A pending todo means keep going.

The only places you address the user between stages are: the PRD interview and approval, a relayed question from a stage, the graph-check stop, a build stop, and the final summary.

## Final summary

```
## Pipeline — <Complete | Paused at <stage>>

**Track:** <track>
**Stages run:** <list>   **Skipped (already done):** <list>
**Sprints:** <done> of <total>   **Merge mode:** <main | epic>
<epic only:> **Epic PR awaiting your review:** <url>
**Next:** <one line — merge the epic PR / fix blocked sprints and re-run / nothing>
```

## Resumability

State lives in `planning/`, not in this skill, and the session file carries the context the other files lack, including a half-finished PRD interview. A new person clones, runs `git switch sprintkit/<track>` (the **Branch** in the session file), and runs the **Resume with** command. The pipeline re-detects the stage from the files and carries on. A half-built plan resumes at Graph, then Build, where autopilot reconciles any `[IN PROGRESS]` sprints itself.

## Constraints

- Checkpoint after every stage, including stopped ones. Stage the named files only, commit and push only on `sprintkit/<track>`, never on `main`, and never force-push.
- Never start Build until the planning MR is merged into `main`.
- Never skip PRD approval; it is the only mandatory human gate before code is written.
- Never invoke `sprintkit-implement`, `sprintkit-review`, `sprintkit-loop` or `sprintkit-sync` directly. Autopilot owns them.
- Never merge to `main` yourself, and never merge an epic PR.
- Never start the build past a failed graph check.
- Forward only the args each stage understands; do not invent new ones.
