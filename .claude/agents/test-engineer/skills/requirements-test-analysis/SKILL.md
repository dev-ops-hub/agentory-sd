---
name: requirements-test-analysis
description: Use when turning a requirement, user story, or acceptance criterion into testable scope - identifying ambiguity and building the traceability link before any test case is written
---

# Requirements Test Analysis

## Overview

Tests must trace to a requirement, not to the implementation that happens to exist. This skill is the first QA pass over a requirement source — reading it, finding what's actually testable, and flagging what isn't — before `../test-case-design/SKILL.md` turns it into concrete cases.

**Core principle:** if a requirement can't be read as an observable pass/fail condition, it isn't ready to test yet — that's a gap to flag, not a gap to fill with assumption.

## When to Use

- A new story, sprint spec, or PRD section is about to be tested
- Acceptance criteria exist but seem incomplete or ambiguous
- Deciding whether a bug report describes an actual requirement violation or a feature request

## Sources to Inspect

Read, in priority order, whatever exists for the scope:

1. Acceptance criteria (the most specific, test it as literally written)
2. User story / sprint spec
3. PRD section (FR/NFR IDs)
4. `planning/constitution.md` MUST rules touching the scope — these override anything else and apply regardless of whether the story mentions them
5. API specification (OpenAPI/Swagger) for endpoint-shaped work
6. Architecture docs / ADRs for cross-component behavior
7. Existing tests — what's already covered, so new work doesn't duplicate it
8. Issue/bug descriptions, for defect-reproduction scope

Never generate test cases solely by reading the implementation — that only proves the code does what it does, not what it should do. If no requirement source exists for a scope, say so as a Gap rather than reverse-engineering "requirements" from the code.

## Finding Ambiguity

For each acceptance criterion, check:

- Does it state an observable result (status code, UI text, persisted value), or just an intention ("the user can manage their watchlist")?
- Does it cover the failure/error path, or only the happy path?
- Does it conflict with another criterion, the PRD, or a constitution MUST rule?
- Does it imply a boundary (a max, a min, a timeout) without stating the exact value?

An ambiguous criterion is a Gap for the owning product role (`product-manager`/`technical-product-manager` in this repo's agent set) to resolve — pick the most literal reading to continue test design meanwhile, and record it as an assumption, not a silent guess.

## Building the Traceability Chain

```
Requirement (FR/NFR id or story)
      ↓
Acceptance criterion
      ↓
Test scenario (this skill's output)
      ↓
Test case (../test-case-design)
      ↓
Execution result
      ↓
Evidence (../test-evidence)
```

Record the chain as you go — see `../requirements-traceability/SKILL.md` for the matrix format. A requirement with no scenario, or a scenario with no case, is a coverage gap to surface explicitly, not an omission to let slide silently.

## Output

For the dispatched scope: the list of acceptance criteria read, which are directly testable as written, which are ambiguous (with the specific ambiguity named), and which constitution MUST rules apply regardless of what the story says. Feed the testable criteria into `../test-case-design/SKILL.md`.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Writing test cases from the code instead of the requirement | Read the requirement source first; use code only to understand how to exercise it |
| Treating an intention ("users can trade confidently") as a testable criterion | Decompose into the observable conditions that intention implies, or flag as too vague |
| Silently picking an interpretation for an ambiguous criterion | Record it as an assumption and flag the Gap |
| Skipping constitution MUST rules because the story doesn't mention them | MUST rules apply regardless of story scope — check them explicitly |

## Quick Reference

| Source | Priority | Note |
|---|---|---|
| Acceptance criteria | 1 | Most specific — test as literally written |
| Constitution MUST rules | Always applies | Overrides story scope, not conditional on being named |
| PRD FR/NFR | 2 | Context and traceability ID |
| Existing tests | Check before writing new ones | Avoid duplicate coverage |
| The implementation itself | Never a sole source | Proves what it does, not what it should |
