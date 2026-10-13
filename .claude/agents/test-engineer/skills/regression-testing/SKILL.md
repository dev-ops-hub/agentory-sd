---
name: regression-testing
description: Use when verifying a change didn't break existing behavior - selecting what to re-test after a fix, feature, or dependency change, and re-testing after remediation
---

# Regression Testing

## Overview

Regression testing confirms previously-working behavior still works after a change — a different question from "does the new behavior meet its criteria" (`../acceptance-testing/SKILL.md`). The core risk this guards against: a fix for one defect introduces or reveals another, or a change touches shared code with effects outside its stated scope.

## When to Use

- After a defect fix, before closing it — re-test the original symptom AND the surrounding area
- After a merge, before marking a sprint/story done
- A dependency, library, or shared utility changed and multiple features consume it

## Regression Selection — Not Everything, Not Nothing

Running the entire suite for every change is safe but not always necessary; running nothing is never safe. Select by:

| Signal | Regression scope |
|---|---|
| Fix touches shared code (a utility, a shared component, a middleware) | Re-test every consumer of that shared code, not just the one that reported the bug |
| Fix touches an isolated, single-purpose function | Re-test that function's existing test suite plus the specific defect's reproduction |
| Change is to a money/state-transition path | Full regression on that path's existing suite — the constitution's integrity rules apply regardless of how small the diff looks |
| Dependency/library version bump | Re-test every feature with a documented dependency on changed behavior in that library |

When in doubt about scope, widen it — a missed regression costs more than an extra test run.

## The Regression Cycle

1. **Reproduce the original defect** — confirm it exists before the fix (if not already confirmed via `../defect-triage/SKILL.md`).
2. **Re-test after the fix** — the exact scenario that was broken now passes.
3. **Re-test the surrounding area** — the regression-selection scope above, not just the one scenario.
4. **Re-run the existing automated suite** — a green run of the one new/fixed test is not a green suite; see `../../shared-skills/verification-before-completion/SKILL.md` for why "the test I wrote passes" doesn't substitute for the actual regression check.
5. **Watch for new regressions the fix introduced** — a fix that touches shared state, locking, or a shared schema can break something that was passing before. Don't close a defect purely because its own reproduction now passes.

## This Is Not Retesting Until Green

Never rerun a failing test repeatedly, with no code change, until it happens to pass, and then report success — that is the `../defect-triage/SKILL.md` FLAKY classification's job, not a regression-testing shortcut. A regression suite that passes intermittently with no code change between runs is itself a finding, not noise to retry past.

## Output

A regression report: what was re-tested and why that scope was chosen, pass/fail per item, and any new finding the fix introduced (reported via `../defect-triage/SKILL.md` like any other defect — a regression introduced by today's fix is still a defect).

## Common Mistakes

| Mistake | Fix |
|---|---|
| Only re-testing the exact reported symptom | Widen scope to the shared code's other consumers per the selection table |
| Treating "my new test passes" as "the suite passes" | Run the full existing suite, not just the new/changed test |
| Rerunning a flaky regression test until green | Classify as FLAKY and investigate; don't retry past it |
| Closing a defect because the original symptom is gone, without checking for a new one | Explicitly check the surrounding area the fix touched |

## Quick Reference

| Change type | Minimum regression scope |
|---|---|
| Isolated bugfix | That function's suite + the specific reproduction |
| Shared utility/component change | Every known consumer |
| Money/state-transition path | Full existing suite on that path |
| Dependency bump | Every feature with documented reliance on changed behavior |
