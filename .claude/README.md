# .claude

Sub-agent definitions and shared skills for this repository. See `CLAUDE.md` at the repo root for the project constitution and sprintkit workflow.

## Security scanners (security-auditor agent)

The `security-auditor` agent (`.claude/agents/security-auditor.md`) runs deterministic scanners before semantic review, when they're installed. None are required — a missing scanner is noted in the audit report's "Not checked" section and the agent falls back to manual review for that pass instead of skipping it or installing anything itself (it never provisions tools).

Install any or all of these locally to get full scanner coverage:

```bash
# macOS (Homebrew)
brew install semgrep trivy checkov gitleaks syft grype
```

```bash
# Linux / manual
pip install semgrep checkov
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/scripts/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
curl -sfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

| Scanner | Checks |
|---|---|
| `semgrep` | Application code SAST (injection, insecure patterns) |
| `trivy` | Containers, filesystem, IaC misconfiguration, known-vulnerability scanning |
| `checkov` | Terraform/CloudFormation/Kubernetes/Bicep misconfiguration |
| `gitleaks` | Secrets committed to the repo or its history |
| `syft` | SBOM generation for a dependency tree |
| `grype` | Known-vulnerability matching against an SBOM or image |

Verify what's installed:

```bash
for t in semgrep trivy checkov gitleaks syft grype; do command -v "$t" >/dev/null && echo "$t: installed" || echo "$t: not found"; done
```

## Skills

The agent pipeline that builds this project. These are live — Claude Code loads
them automatically for anyone working in this repo, so cloning it gets you the
same setup that produced the game.

### The pipeline

```
sprintkit-start → sprintkit-plan → sprintkit-design → a sprint graph
                                      │
                 ┌────────────────────┼────────────────────┐
                 ▼                    ▼                    ▼
          implement ⇄ review   implement ⇄ review   implement ⇄ review
                 └────────────────────┼────────────────────┘
                                      ▼
                                    merge → sprintkit-sync → sprintkit-retro
```

The plan is a dependency graph, so anything unblocked runs at once — up to four
sprints concurrently, each in its own git worktree, all driven by one
orchestrator. The merge stays single-file: only the controller merges, one PR at
a time.

| Skill | Role |
|---|---|
| `sprintkit-start` | Interviews you into a full PRD. |
| `sprintkit-plan` | Converts a PRD into sprints with testable acceptance criteria, and declares the dependencies between them — which is what decides how wide the build fans out. |
| `sprintkit-design` | Builds design artifacts between plan and graph: `planning/ux/` screen/design docs plus `planning/architecture/design.md`, then records sprint `**Design:**` status lines. |
| `sprintkit-graph` | Draws the plan as a dependency graph and predicts the schedule — what fans out, which runner gets what, the critical path, and an audit of cycles and accidental serialisation. Read-only. |
| `sprintkit-implement` | Writes the code for a sprint's stories and opens the PR. |
| `sprintkit-review` | Board-based review against sprint acceptance criteria, PRD intent, test/security/architecture/product/UX acceptance, with PR verdict posting. |
| `sprintkit-sync` | Reconciles sprint status after a merge. |
| `sprintkit-jira` | Exports epics, stories, sprints, sub-tasks and agent decisions to Jira Cloud, and publishes the planning documents to Confluence (both via the Atlassian MCP), when `agent-config/jira_confluence.json` is configured. Always writes `planning/scratchpad/jira-export.md`, the decision log and the ID mapping; runs automatically at the `sprintkit-start` and `sprintkit-plan` gates. |
| `sprintkit-retro` | Closes the cycle — what shipped vs. planned, what to change, durable memory entries. |

#### Relevant recent changes

- `sprintkit-design` is now the explicit stage between planning and graph/autopilot, so UI and system design are in place before build fan-out.
- `sprintkit-review` now runs a multi-agent review board (test, security, architecture, product, UX) and posts one PR verdict.
- `sprintkit-loop` and `sprintkit-autopilot` now carry board artifact/report status through each review cycle.
- `sprintkit-sync` now treats board artifacts under `agent-docs/review-reports/` as first-class review evidence.

#### Choosing which sprint specs to write

`sprintkit-plan` always plans the whole PRD into one sprint file, but you can
write the detailed specs (`planning/specs/sprint-N.md`) for only some sprints.
Put a `specs:` selector after the track in the args:

| Args | Writes specs for |
|---|---|
| `/sprintkit-plan track:default` | Asks you once which sprints to spec, and suggests `next`. |
| `/sprintkit-plan track:default specs:1-3` | Sprints 1 to 3. |
| `/sprintkit-plan track:default specs:2,4,7` | Exactly Sprints 2, 4 and 7. |
| `/sprintkit-plan track:default specs:next` | Every `[NOT STARTED]` sprint with no spec yet whose dependencies are `[DONE]` or in the same batch. |
| `/sprintkit-plan track:default specs:all` | Every sprint that is not `[DONE]`. |

**To plan only some sprints, use `specs:`, not `track:`.** `track:` names a
separate project with its own PRD, sprint file and session file, so
`/sprintkit-plan track:sprint1-3` does not mean "sprints 1 to 3". It looks for
`planning/sprint1-3-product-req-document(PRD).md`, finds none and offers to
start a new, empty track. For sprints 1 to 3 of the existing default track, run
`/sprintkit-plan track:default specs:1-3`. The sprint file still covers the
whole PRD, so the dependency graph stays complete; only the specs are limited
to the sprints you name.

Omit the track and it picks the only track, or asks if there are several. A
spec is only written for the sprints you select; coverage, the checker and the
audit run on those specs only. Sprints left out are marked
`**Spec:** not written yet`.

To continue later, run it again, for example
`/sprintkit-plan track:default specs:next`. It picks up the sprints that still
have no spec. A selected sprint that already has a spec is revised, not
rewritten.

**Sprints marked `[DONE]` are frozen.** The plan skill never edits their
section in the sprint file, their spec or their summary row, even if you name
them. If a change would affect one, it stops and asks; the usual fix is a
follow-up sprint via `sprintkit-sync`.

When every spec from the run has passed the `product-auditor`, `sprintkit-plan`
hands off to `sprintkit-graph` by itself (it does not if a spec is still open,
or when the pipeline is driving, since the pipeline runs the graph stage).

`sprintkit-autopilot` does not check for specs. Select every sprint you plan to
build before you start it, or it builds an unspecced sprint from the sprint
file alone.

### The loops

The part the talk is actually about. These orchestrate the skills above rather
than doing the work themselves.

| Skill | Role |
|---|---|
| `sprintkit-loop` | Implement → review → fix → re-review, until approved or a human is genuinely needed. Hard-stops at 8 cycles. |
| `sprintkit-autopilot` | The whole PRD, end to end — as a **scheduler**, not a list walk. Reads the plan as a dependency graph, runs every unblocked sprint (up to four at once, in separate worktrees), merges each PR itself, and refills the freed runner with whatever just became unblocked. A failed sprint blocks only its own subtree; the rest of the graph keeps building. Supports epic-branch mode so `main` stays releasable. |

#### Run one sprint with the loop

Use `sprintkit-loop` when you want to implement and review a single sprint,
including follow-up fixes based on review feedback:

```text
/sprintkit-loop sprint:2
```

`sprint:2` selects Sprint 2 explicitly, so the loop does not need to infer
which sprint you mean from the sprint plan's `[IN PROGRESS]` marker. If the
repository has multiple tracks, name the track too:

```text
/sprintkit-loop sprint:2 track:default
```

The loop implements the sprint, opens a PR, and repeats review/fix cycles until
the PR is approved or it needs human input (maximum 8 cycles). It does **not**
merge the PR; merge it yourself, then run `sprintkit-sync` to update the sprint
plan. Use `sprintkit-autopilot` instead when you want the dependency scheduler
to build multiple unblocked sprints.

### Evals

Five skills carry an eval harness under `evals/`:

```
sprintkit-start/evals/evals.json
sprintkit-sync/evals/evals.json
sprintkit-plan/evals/evals.json
sprintkit-plan/evals/files/kopi-uncle/planning/product-req-document(PRD).md
sprintkit-graph/evals/evals.json
sprintkit-graph/evals/trigger_evals.json
sprintkit-graph/evals/files/kopi-uncle/planning/sprint.md
sprintkit-graph/evals/files/broken/planning/sprint.md
sprintkit-implement/evals/evals.json
sprintkit-implement/evals/trigger_evals.json
sprintkit-implement/evals/files/kopi-uncle/planning/product-req-document(PRD).md
sprintkit-implement/evals/files/kopi-uncle/planning/sprint.md
```

These are what makes a skill an engineering artifact rather than a wish.
`evals.json` grades output with and without the skill loaded;
`trigger_evals.json` measures whether the description fires on the right
prompts and stays quiet on the wrong ones — ten prompts that should fire it and
ten that should not, because a skill that triggers on everything is as broken as
one that never triggers. Run them with `claude plugin eval`.

The `evals/files/` fixtures are a condensed Kopi Uncle PRD and sprint plan,
copied into the eval sandbox so the runs are self-contained. The sprint fixture
marks Sprints 1–2 as DONE and Sprint 3 as NOT STARTED, which is what lets the
"implement the current sprint" eval check whether the skill actually works out
where it is instead of guessing.

### Provenance and caveats

- Snapshot of the author's personal `~/.claude/skills/` as of **2026-08-26**,
  since diverged. It is not a live mirror.
- **Renamed under a `sprintkit-` prefix**, and that is not cosmetic. A
  user-scoped skill shadows a project-scoped one of the same name, so while
  these carried their original names they were silently overridden on any
  machine that already had them in `~/.claude/skills/` — including the author's,
  which is where the repo's own fixes are supposed to take effect. Under a
  distinct prefix the repo's copies are the ones that run, and both sets can
  coexist. Attendees lifting these into their own projects can drop the prefix
  or keep it; keeping it is safer for exactly the same reason.
- Eight skills from that set were left out as irrelevant to this project:
  `epic-planner`, `ideate`, `task-impl-pr`, `task-impl-pr-review-loop`,
  `pr-reviewer`, `codebase-auditor`, `scrum-task-adder`, `sprint-compactor`.
  Where the remaining skills referred to them, the routing advice was rewritten
  to describe the situation instead of naming a skill that isn't here.
- Absolute `~/.claude/...` paths were rewritten repo-relative so the helper
  resolves from a clean clone.
- The `sprintkit-plan` and `sprintkit-implement` evals were originally written
  against a private project and referenced it by absolute path. They have been
  re-domained onto Kopi Uncle with self-contained fixtures. Structure,
  assertions and intent are unchanged — only the subject matter differs.
- No personal configuration is included. The author's global `CLAUDE.md`
  (language preferences, machine setup, install rules) stays out of this repo
  by design — these skills are the transferable part.

### Using them elsewhere

Copy any skill directory into `.claude/skills/` in your own project, or into
`~/.claude/skills/` to have it everywhere. They assume `git` and the `gh` CLI,
and the sprint skills assume a `planning/product-req-document(PRD).md` and
`planning/sprint.md` in the conventional shape — run `sprintkit-start` and
`sprintkit-plan` first and you get that for free.

### Third-party tools to install

Required for day-to-day sprintkit execution:

- `git`
- One git host CLI: `gh` (GitHub) or `glab` (GitLab)
- Auth for your chosen host CLI (`gh auth login` or `glab auth login`)

Recommended (used by specific skills):

- Atlassian MCP connection for Jira/Confluence publishing (`sprintkit-jira`)
- Security scanner toolchain for `security-auditor`: `semgrep`, `trivy`, `checkov`, `gitleaks`, `syft`, `grype`
- Claude plugin eval command support if you run `evals/` (`claude plugin eval`)

Quick install (macOS/Homebrew):

```bash
brew install git gh glab semgrep trivy checkov gitleaks syft grype
```

Host CLI auth:

```bash
gh auth login
glab auth login
```
