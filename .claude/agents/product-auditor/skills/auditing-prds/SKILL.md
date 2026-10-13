---
name: auditing-prds
description: Use when a sprintkit PRD (planning/product-req-document(PRD).md or planning/<track>-product-req-document(PRD).md) has been drafted or revised and must be stress-tested before sprint planning, including re-audits after refinement rounds
---

# Auditing PRDs

## Overview

Read the PRD as a sceptical engineer who must build from it tomorrow and a QA who must test it. **Core principle:** find weaknesses, not wins; every finding comes with a fix and an owner who can actually close it.

Report with the `reporting-audit-findings` skill. Owner `AUTHOR` here means the `product-manager` agent; give its **Brief** the skill folder to read (from `.claude/agents/product-manager/skills/`), the target section and the facts to pass.

## Standards

Read before auditing: `deliver-prd` (section depth, metric testability), `deliver-edge-cases` (failure-mode categories), and the adversarial stance and cross-cutting checks in `utility-pm-critic/references/pm-critic-agent.md` (falsifiability, evidence for assertions, internal consistency, coverage against the contract). Ignore pm-critic's plugin-specific paths and invocation notes.

## Passes

| # | Pass | Check |
|---|---|---|
| 1 | Problem | Stated without a solution baked in; who has it and what it costs |
| 2 | Goals | Every goal has a metric, a baseline and a target; none is invented (a target without a source is `USER`) |
| 3 | Requirements | Every §6 requirement has an `FR-n` ID and a pass/fail condition; no duplicates (`speckit-analyze` pass A) or vague adjectives without a measure (pass B) |
| 4 | Scope | In Scope and Out of Scope explicit; no requirement contradicts Out of Scope; v1 vs later is clear |
| 5 | Consistency | Numbers, names and priorities agree across sections (`speckit-analyze` pass F) |
| 6 | Failure modes | Failure, boundary and empty states covered per feature area (`deliver-edge-cases` categories) |
| 7 | Risks | Each has a concrete mitigation, not "monitor" |
| 8 | Constitution | If `planning/constitution.md` exists: no requirement, goal or technical choice contradicts a MUST rule. Always P0, owner `USER` (change the PRD or amend the constitution), quoting the principle |
| 9 | Evidence | Claims about users, markets or the codebase are backed; verify codebase claims with Grep/Glob |
| 10 | Template | Section numbering and headings match the sprintkit template, since `sprintkit-plan` parses them |

## Common mistakes

- Proposing new features. Flag missing coverage of what the PRD already commits to, nothing more.
- Owner `AUTHOR` for a finding that needs a number the PRD lacks. That is `USER`.
- A long list of vague findings. A short list of specific ones with fixes is worth more.
