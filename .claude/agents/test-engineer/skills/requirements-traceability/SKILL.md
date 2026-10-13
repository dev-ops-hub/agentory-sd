---
name: requirements-traceability
description: Use when building or checking the traceability matrix linking requirements to test coverage - identifying which requirements have no corresponding test
---

# Requirements Traceability

## Overview

A traceability matrix proves (or disproves) that every requirement has test coverage, and lets anyone trace a failing test back to the requirement it protects. Without it, "we tested the feature" is an unverifiable claim.

## When to Use

- Before a release-readiness assessment, to find untested requirements
- Checking whether a sprint's stories all have corresponding test coverage
- Tracing a production incident back to whether a test should have caught it (and didn't, or doesn't exist)

## The Chain

```
Requirement (FR/NFR id, user story, constitution MUST rule)
      ↓
Acceptance criterion
      ↓
Test scenario
      ↓
Test case
      ↓
Execution result
      ↓
Evidence
```

Each link should be nameable. A requirement with no scenario is a coverage gap. A scenario with no concrete case is incomplete design. A case with no execution result hasn't actually been run yet (see `../../shared-skills/verification-before-completion/SKILL.md` — "designed" is not "verified").

## Matrix Format

| Requirement ID | Acceptance criterion | Test case(s) | Result | Evidence |
|---|---|---|---|---|
| FR-30 | Trade requires explicit Confirm, not typed text | TC-014, TC-015 | Pass | `test_confirm_requires_button_not_chat_text` |
| FR-32 | Confirm is idempotent — repeated/concurrent confirm yields exactly one trade | TC-022 | Pass | `test_double_confirm_race_yields_one_trade` |
| FR-26 | Unwatching a ticker does not change its position | — | **Untested** | No test case found |

A row with no test case is the matrix doing its job — surfacing the gap rather than letting it hide inside a "looks covered" impression.

## Building It

1. Enumerate requirements for the scope from `../requirements-test-analysis/SKILL.md`'s source list — including constitution MUST rules relevant to the scope, which bind regardless of whether a story names them.
2. For each, find the test case(s) that exercise it. Search by name/tag/docstring convention already used in the codebase — don't assume a case exists because a function with a similar name does.
3. Mark any requirement with zero matching cases as **Untested**, explicitly, rather than omitting the row.
4. Mark any case that doesn't trace back to a requirement as unlinked — not necessarily wrong, but worth asking why it exists (dead test for a removed feature? a case someone wrote without a stated requirement?).

## Output

The matrix feeds directly into `../qa-release-assessment/SKILL.md`'s requirements coverage counts (Passed/Failed/Blocked/Untested) and highlights untested requirements as a residual risk the release assessment must name, not silently absorb into "mostly covered."

## Common Mistakes

| Mistake | Fix |
|---|---|
| Building the matrix from the test suite outward ("what do these tests cover") | Build it from requirements inward — the gap you're looking for is the requirement with nothing pointing at it |
| Treating "a test file with a similar name exists" as coverage without reading it | Confirm the case actually exercises the requirement's observable condition |
| Omitting untested requirements instead of listing them as Untested | Every requirement gets a row, even an empty one |
| Not re-checking the matrix after scope changes mid-sprint | Rebuild/update for the final scope, not the one at sprint start |

## Quick Reference

| Row state | Meaning |
|---|---|
| Requirement → case → Pass | Verified covered |
| Requirement → case → Fail | Covered, currently broken — defect, not a documentation gap |
| Requirement → no case | **Untested** — real coverage gap |
| Case → no requirement | Unlinked — investigate why it exists |
