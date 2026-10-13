---
name: acceptance-testing
description: Use when verifying a feature against its acceptance criteria rather than against general code quality - the pass/fail check that decides whether a story is actually done
---

# Acceptance Testing

## Overview

Acceptance testing answers one question per criterion: does the system do exactly what the acceptance criteria say, as written? This is narrower than general QA — it is not "is this good code" (that's `code-review`) and not "did I find any bug" (that's `../exploratory-testing/SKILL.md`); it is a literal check against the stated contract.

## When to Use

- A story or sprint spec marks acceptance criteria that need verification before sign-off
- Deciding whether a story is actually "done" vs. merely "code written"
- Re-verifying acceptance after a fix, to confirm the original criterion now holds (not just that the specific bug symptom is gone)

## Method

1. Take the acceptance criteria as analyzed in `../requirements-test-analysis/SKILL.md` — the testable ones, with ambiguities already flagged.
2. For each criterion, execute the system (via its real interface — HTTP, UI, CLI) and record the actual result against the stated expected result.
3. Mark each criterion: **Passed** (observed result matches), **Failed** (observed result contradicts — this becomes a defect, see `../defect-triage/SKILL.md`), **Blocked** (can't be executed — missing dependency, missing data, environment issue), or **Untested** (not yet attempted, state why).
4. A criterion written as Given/When/Then is tested exactly as structured — set up the Given, perform the When, assert the Then; don't substitute a different setup or action because it seemed equivalent.

## Acceptance vs. Everything Else

| This agent also does... | How it's different from acceptance testing |
|---|---|
| Exploratory testing | Unscripted — looking for defects the criteria didn't anticipate, not checking a known criterion |
| Regression testing | Confirms *previously working* behavior didn't break, not that *new* behavior meets its criteria |
| Code review | Judges code quality/maintainability, not behavior-vs-contract |
| Test-case design | Produces the cases; acceptance testing executes them against the literal criteria |

## Handling a Criterion That Seems Wrong

If executing a criterion as literally written produces a result that seems like bad product behavior (e.g., the criterion says X but X seems like the wrong UX), that is **not** license to test a different behavior instead. Report: the criterion as written, what it produces when followed literally, and why it seems wrong — as a Gap for the product role, not a silent substitution. Testing what you think the system *should* do instead of what the criterion *says* defeats the purpose of having criteria.

## Output

Per-criterion verdict (Passed/Failed/Blocked/Untested), feeding into `../requirements-traceability/SKILL.md`'s coverage matrix and ultimately `../qa-release-assessment/SKILL.md`'s "Requirements Passed/Failed/Blocked/Untested" counts.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Testing "the spirit" of a criterion instead of what it literally says | Test as written; flag disagreement separately as a Gap |
| Marking "Blocked" criteria as "Failed" | Blocked means untestable right now (missing data/env), not a defect — distinguish them |
| Re-running a failed criterion after a fix and calling it done without checking it was the actual criterion that now passes | Re-verify the specific stated expected result, not just "looks better now" |
| Skipping criteria that look tedious or obviously-fine | Every stated criterion gets a verdict; "obviously fine" is not evidence |

## Quick Reference

| Verdict | Means |
|---|---|
| Passed | Observed result matches the criterion as written |
| Failed | Observed result contradicts the criterion — raise as a defect |
| Blocked | Can't execute right now — missing dependency, data, or environment |
| Untested | Not yet attempted — state why, don't silently omit |
