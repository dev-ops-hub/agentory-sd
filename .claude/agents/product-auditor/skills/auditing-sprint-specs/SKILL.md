---
name: auditing-sprint-specs
description: Use when a sprintkit sprint spec (planning/specs/*.md) has been written or revised and must be checked against the PRD, the sprint plan and the constitution before an engineer builds from it, including when its author marked it ready or its coverage checker printed OK
---

# Auditing Sprint Specs

## Overview

A sprint spec can pass `check_spec.py` (every ID linked, every section present) and still be wrong. **Core principle:** verify, don't trust: re-derive every number, re-check every citation against the text it cites, and re-compute every expected test output from the requirements.

Report with the `reporting-audit-findings` skill. Owner `AUTHOR` here means the `technical-product-manager` agent.

## Inputs

The spec, the PRD, the sprint plan (the sprint's section and its `**Touches:**`), `planning/constitution.md`, and specs of the sprints it depends on if they exist.

## Passes

Run every pass; each finding names the pass that found it. Passes 1-6 adapt `speckit-analyze` (its spec/plan/tasks become PRD/sprint plan/spec); use `speckit-checklist`'s quality dimensions (completeness, clarity, consistency, measurability, coverage) to judge wording.

| # | Pass | Check |
|---|---|---|
| 1 | Citation | For every FR **Source**, open the cited PRD section, story criterion or principle and confirm it states that requirement. Check **each value** of an FR that lists several (a token table, an enum, a set of limits), not the FR as a whole: a section that shows one example supports that example only. A value the source does not state (vocabulary, aliases, limits, error types) is unsourced. A real gap must appear as an `A`/`Q` item in section 9, not as a citation |
| 2 | Plan fidelity | Every sprint-plan criterion for this sprint is refined by an AC that keeps all of it: every value, every alternative ("siew-dai **or** kosong"), every quantifier ("all six slots") |
| 3 | Constitution | Every MUST principle that applies: no FR, interface or AC contradicts it, and section 7 does not claim compliance that the spec breaks |
| 4 | Numbers | Recompute every count, total and threshold from the PRD's rules; show the arithmetic in the finding |
| 5 | Test oracles | For each TC, derive the expected output from the FRs yourself and compare. Check that the TC exercises its whole AC (all values, all slots, both outcomes), not one sample |
| 6 | Scope | Files changed stay inside **Touches** (or the files the stories name); no work from another sprint; no behaviour beyond the sources |
| 7 | Honesty | **Status** `ready` only if section 9 has no open `Q`/`C`; every conflict between PRD, plan and constitution you found appears as a `C` item; "Open items: None" is checked against passes 1 and 3 |
| 8 | Ambiguity | Inputs whose result the spec leaves undecided (case, whitespace, invalid-but-well-formed input): P2 if a safe reading exists, otherwise P1 `USER` |

## Common mistakes

- Trusting a citation because it names the right PRD section. Read the section.
- Checking that a TC exists for an AC instead of checking that its expected value is right.
- Fixing a conflict in the report ("use the constitution's gate") instead of raising it for the user.
- Stopping after the obvious blockers. Passes 1, 6 and 7 find what the others miss.
