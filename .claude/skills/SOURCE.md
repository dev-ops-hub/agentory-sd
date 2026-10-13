# Source

The repository-level skill library in `.claude/skills/` mixes local sprintkit skills and externally sourced skills. This file records origin, version, licensing context, and local deviations in the same format used by other `SOURCE.md` files in this repository.

| Skill or group | Origin | Version | License | Local changes |
|---|---|---|---|---|
| `sprintkit-*` suite (`start`, `plan`, `implement`, `review`, `sync`, `loop`, `autopilot`, `graph`, `design`, `jira`, `pipeline`, `retro`) | Snapshot from the author's personal skills (see `.claude/skills/README.md` provenance notes), evolved in this repository | Snapshot date in README: 2026-08-26, then repository-local updates | Same terms as this repository unless otherwise noted per file | Paths and flow adapted to this repository (`planning/`), plus local orchestration and policy updates |
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

## Notes

- Local sprintkit references should continue to point to `/sprintkit-start`, not `/sprintkit-prd`.
- When importing sprintkit content from `uzyn/kopi-uncle`, translate `docs/*` paths to `planning/*` paths.
- For repository-installed skills under `.claude/skills/`, prefer local skill names (for example `dispatching-parallel-agents`) over namespaced external aliases.

## Refreshing

1. For `dispatching-parallel-agents` and `writing-skills`, refresh from `obra/superpowers`, then update the version/date row above.
2. For sprintkit cross-repo sync from `uzyn/kopi-uncle`, preserve local repository conventions:
	 - `sprintkit-start` naming
	 - `planning/` path layout
	 - team-aware implementation policy additions
3. Record every intentional local modification in the Local changes column.
