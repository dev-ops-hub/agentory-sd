# Source

The repository-level skill library in `.claude/skills/` mixes local sprintkit skills and externally sourced skills. This file records origin, version, licensing context, and local deviations in the same format used by other `SOURCE.md` files in this repository.

| Skill or group | Origin | Version | License | Local changes |
|---|---|---|---|---|
| `sprintkit-*` suite (`start`, `plan`, `implement`, `review`, `sync`, `loop`, `autopilot`, `graph`, `design`, `jira`, `pipeline`, `retro`) | Snapshot from the author's personal skills (see `.claude/README.md` provenance notes), evolved in this repository | Snapshot date in README: 2026-08-26, then repository-local updates | Same terms as this repository unless otherwise noted per file | Repository paths and flow, orchestration, team policies, Confluence publishing, story-point recording, branch safety, and review-board behavior are adapted locally; see **Repository-local sprintkit changes** below |
| `dispatching-parallel-agents` | [obra/superpowers](https://github.com/obra/superpowers) | Installed from upstream HEAD on 2026-10-08 (unpinned) | MIT (per upstream repository) | Added local workspace-skill integration guidance for `.claude/skills` routing |
| `writing-skills` | [obra/superpowers](https://github.com/obra/superpowers) | Installed from upstream HEAD on 2026-10-08 (unpinned) | MIT (per upstream repository) | None after install |
| `daisyui` | Project-level skill set in this repository | Repository-local | Same terms as this repository unless noted in file headers | Parent guidance slimmed to reduce token overhead |

## Upstream URLs

| Skill | Obtained from |
|---|---|
| dispatching-parallel-agents | <https://github.com/obra/superpowers/tree/main/skills/dispatching-parallel-agents> |
| writing-skills | <https://github.com/obra/superpowers/tree/main/skills/writing-skills> |

## Sprintkit comparison with uzyn/kopi-uncle

Comparison date: 2026-10-08

Reference repository: <https://github.com/uzyn/kopi-uncle>
Reference commit inspected: `61d8944e230529b1aec9adc5b3ae0d0e4d96bb3b`

### Key differences

1. Entry skill naming
- This repository uses `sprintkit-start` as the PRD entry skill.
- `uzyn/kopi-uncle` uses `sprintkit-prd`.

2. Planning path conventions
- This repository uses `planning/product-req-document(PRD).md` and `planning/sprint.md`.
- `uzyn/kopi-uncle` uses `docs/prd.md` and `docs/sprint.md`.

3. Parallel-dispatch skill reference
- This repository uses local name `dispatching-parallel-agents` in sprintkit flows.
- `uzyn/kopi-uncle` references `superpowers:dispatching-parallel-agents`.

4. Local team-workflow extensions
- This repository adds explicit team-routing, preflight estimation/design/status, peer-review gate, and Jira attribution policies in:
	- `sprintkit-implement`
	- `sprintkit-loop`
	- `sprintkit-autopilot`

5. Core orchestration alignment
- Both repositories keep the same core loop architecture:
	- `sprintkit-loop` handles implement -> review -> fix -> re-review
	- `sprintkit-autopilot` schedules dependency-aware fan-out with centralized merge control

## Repository-local sprintkit changes

The following repository-specific behavior is maintained in addition to the
path, naming, and orchestration differences above. These changes were present
in the local sprintkit skills on 2026-10-15:

1. **Design and Confluence publishing**
   - `sprintkit-design` documents that `planning/ux/**` publishes through
     `sprintkit-jira` when Confluence is configured, under the configured UX
     folder (`confluence.folders.ux`, default "User Interface Design").
   - `planning/architecture/design.md` is now published as the `architecture`
     document type under the configured architecture folder
     (`confluence.folders.architecture`, default "Architecture Design").
     This is distinct from `adr`, which continues to publish individual
     Nygard-shaped ADR files.
   - `sprintkit-jira` supports folder lookup/creation and records folder IDs in
     the mapping. It places pages under the folder, moves already-mapped pages
     when needed, reports newly created folders and moves, and asks before
     creating a second folder when it finds a likely near-duplicate. It also
     records creator/reviewer/approver/source attribution and page-version
     state for sync.

2. **Implementation preflight and branch safety**
   - `sprintkit-implement` estimates stories only on the scale `1, 3, 5, 7, 13`.
     It must record every estimate with attribution in
     `planning/scratchpad/jira-comments.md` regardless of Jira configuration;
     `sprintkit-jira` then optionally publishes the estimate to Jira.
   - Before switching branches, it reports the current branch, dirty files,
     and commits not on the base, then waits for the user's choice. It skips
     the confirmation only when already on the target sprint branch or when an
     unattended loop/autopilot runner owns an isolated worktree.

3. **Review board and verdict reporting**
   - The sprint review board has three members: `test-engineer`,
     `security-auditor`, and `product-manager`. The product manager covers
     architecture fit, scope and acceptance criteria, product intent, and UX
     conformance that were previously split across four acceptance reviewers.
   - When self-approval is blocked, `sprintkit-review` posts the ready verdict
     as a formal GitHub review (or a GitLab note), not a plain GitHub issue
     comment. The `READY_TO_MERGE` marker must be visible in the formal-review
     list consumed by `sprintkit-loop` and `sprintkit-autopilot`.

4. **Completed-sprint story points**
   - `sprintkit-sync` copies each story's estimate from the local
     `jira-comments.md` record into a `**Story Points:**` line when marking the
     sprint done, whether or not Jira is configured. Missing estimates are
     reported as gaps rather than guessed.

## Notes

- Local sprintkit references should continue to point to `/sprintkit-start`, not `/sprintkit-prd`.
- When importing sprintkit content from `uzyn/kopi-uncle`, translate `docs/*` paths to `planning/*` paths.
- For repository-installed skills under `.claude/skills/`, prefer local skill names (for example `dispatching-parallel-agents`) over namespaced external aliases.
- Keep **Repository-local sprintkit changes** current whenever these policies or integrations change; describe only behavior implemented by the skills, not planned behavior.

## Refreshing

1. For `dispatching-parallel-agents` and `writing-skills`, refresh from `obra/superpowers`, then update the version/date row above.
2. For sprintkit cross-repo sync from `uzyn/kopi-uncle`, preserve local repository conventions:
	 - `sprintkit-start` naming
	 - `planning/` path layout
	 - team-aware implementation policy additions
	 - the repository-local Confluence, story-point, branch-safety, and review-board behavior documented above
3. Record every intentional local modification in the Local changes column.
