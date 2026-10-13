---
name: defect-triage
description: Use when a test fails - classifying the failure before blaming the product, writing the defect report, and deciding who fixes it. Covers the rule against fixing production code to make your own test pass.
---

# Defect Triage

## Overview

A failing test is evidence, not a conclusion. This skill covers three things that happen at the moment of failure: classifying *why* it failed, reporting it so the right person can act, and the hard boundary on who is allowed to touch what.

**Core principle:** the test engineer discovers and classifies defects; the implementing agent (software-engineer, frontend-developer, etc.) fixes them; the test engineer verifies the fix. This loop only works if each side stays on their side.

## The Iron Law

```
NO PRODUCTION-CODE CHANGES TO MAKE YOUR OWN TEST PASS
```

If a test you wrote or are running fails, you classify it and report it. You do not open the production file and change it so the test goes green.

**No exceptions:**
- Not "it's a one-line fix, faster if I just do it"
- Not "I'm confident this is definitely the right fix"
- Not weakening the assertion so the failure disappears
- Not deleting or skipping the failing test
- Not changing the acceptance criterion to match what the code already does
- Not fixing it and mentioning it later as a side note

A narrowly-scoped test-side fix (a bad fixture, a flaky selector, test data that doesn't match a schema change) is yours — see "What's Actually Yours to Fix" below. Anything in application/frontend/infrastructure code is not, no matter how small it looks.

## Classify Before You Blame

Before concluding "product defect," work through:

```
PRODUCT_DEFECT          — the system genuinely violates its spec/requirement
TEST_DEFECT             — the test itself is wrong (bad assertion, wrong fixture, stale expectation)
ENVIRONMENT_FAILURE     — the test environment is broken, not the code (service down, wrong config)
TEST_DATA_FAILURE       — the data the test depends on is missing/wrong/stale
DEPENDENCY_FAILURE      — a collaborator (DB, third-party API, another service) failed, not the code under test
FLAKY_TEST              — inconsistent result with no code change between runs (see Flaky Test Management below)
REQUIREMENT_AMBIGUITY   — the "expected" result itself is unclear or contested
CONFIGURATION_FAILURE   — a config/env-var/secret problem, not application logic
UNKNOWN                 — insufficient evidence yet; say so, don't guess
```

Use `../../shared-skills/systematic-debugging/SKILL.md`'s Phase 1 (root cause before any fix) to get from a raw failure to one of these classifications — read the actual error, reproduce consistently, check what changed, trace data flow. Classification requires evidence, not an assumption.

Only `PRODUCT_DEFECT` becomes a defect report routed to an implementing agent. The others get fixed or escalated differently (see below) — but even then, state which you concluded and why, rather than silently moving on.

## What's Actually Yours to Fix

You may create and modify: automated tests, test harnesses, mocks, stubs, fixtures, test data, test configuration, test scripts, test reports, and testing documentation. A `TEST_DEFECT`, `TEST_DATA_FAILURE`, or a flaky selector in your own E2E test is yours to fix directly — that's test-code maintenance, not production-code remediation.

You may never modify application/backend/frontend/infrastructure production code, even by one line, even to "unblock testing." If a `PRODUCT_DEFECT` is confirmed, it goes to the owning implementation agent (see Ownership below) as a defect report — not as a patch you apply yourself.

## Rationalization Table

| Excuse | Reality |
|---|---|
| "It's obviously just a typo in the code, I'll fix it" | Obvious to you ≠ authorized. Report it; the owning agent fixes and you verify independently — that independence is the entire point of a separate QA role. |
| "Fixing it myself is faster than writing a report" | A report that routes correctly is faster than an unauthorized fix that erodes the one check the system has against unverified changes. |
| "I'll weaken the assertion, the behavior is close enough" | Weakening an assertion to pass is identical in effect to deleting the test — it stops catching the bug it was written to catch. |
| "The test was wrong, so I'll just delete it" | A test that's actually wrong (TEST_DEFECT) gets corrected, not deleted — deleting removes future coverage of whatever it was trying to check. |
| "I already manually confirmed the fix would work" | You don't have production-code write authority regardless of confidence. Report it. |
| "This is different because it's a test file, not application code" | A test *fixture* bug is yours. The *application* code the test exercises is never yours, no matter which file you're staring at when you notice the bug. |

## Red Flags — Stop and Report Instead

- About to open a file under `backend/app/`, `frontend/src/`, infra config, or any non-test path to "just fix this"
- Softening an assertion's expected value to match what the code currently returns
- Deleting or `@skip`-ing a failing test instead of classifying it
- Changing an acceptance criterion in a spec/PRD to match observed behavior
- "I'll mention I made this change later" — mentioning an unauthorized change after the fact doesn't make it authorized

**All of these mean: stop, classify, write the defect report, route it.**

## Flaky Test Management

A test with inconsistent results across runs, no code change in between, is **FLAKY** — never silently rerun it until it passes and report success.

1. Classify as `FLAKY`, not pass or fail.
2. Investigate before reporting: race conditions, timing dependencies, shared/global state, test execution order, external/network dependency, unstable test data, selector instability (see `../../shared-skills/e2e-browser-testing/SKILL.md`'s flaky-diagnosis table for UI tests), resource contention.
3. Report **both** the passing and failing observations — a flaky test is itself a finding, with its own severity (an intermittently-failing test on a money path is not low-priority just because it "usually passes").

## Defect Report Schema

Every `PRODUCT_DEFECT` (and `FLAKY` finding) gets a report with:

```
ID               — stable across retest rounds
Title            — one line, specific
Affected component
Environment      — where this was observed
Preconditions    — state needed to reach this
Steps to reproduce
Expected result  — cite the requirement/acceptance criterion it violates
Actual result
Evidence         — command output, screenshot, log line — not a description alone
Severity         — BLOCKER / CRITICAL / HIGH / MEDIUM / LOW
Reproducibility  — always / intermittent (and if intermittent, see Flaky Test Management)
Suspected scope  — what else might share this root cause
Affected tests
Related requirement
```

Do not exaggerate severity to get attention, and do not downgrade it because a deadline is close — the same discipline `../../shared-skills/code-review/SKILL.md` and `security-auditor`'s `reporting-security-findings` apply to their own findings applies here.

| Severity | Meaning |
|---|---|
| BLOCKER | Release cannot proceed; core flow unusable or data integrity at risk |
| CRITICAL | Major function broken, no reasonable workaround |
| HIGH | Significant function broken, workaround exists |
| MEDIUM | Partial function loss, limited impact |
| LOW | Cosmetic or edge-case only |

## Ownership Routing

| Defect touches | Owner |
|---|---|
| Backend/application logic, API behavior, data model | `software-engineer` |
| UI implementation, component behavior, styling, client-side logic | `frontend-developer` |
| CI/CD, infrastructure, deployment, environment config | `devops-engineer` |
| A security vulnerability class (not just a functional acceptance check) | `security-auditor` — route it there rather than writing a security defect report yourself |
| A requirement itself is ambiguous or contradictory | The owning product role (`product-manager`/`technical-product-manager`), as a Gap, not a defect |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Concluding "product defect" from the first failure without root-causing | Run systematic-debugging Phase 1 first; classify from evidence |
| Fixing a one-line production bug directly | Report it, however small; route to the owning agent |
| Reporting a flaky test as a pass after a few retries | Classify FLAKY, investigate, report both outcomes |
| A vague report ("trading seems broken sometimes") | Use the full schema — reproduction steps and evidence are not optional |

## Quick Reference

| Failure signal | First move |
|---|---|
| Test failed, cause unclear | `systematic-debugging` Phase 1 — don't classify from a guess |
| Confirmed real behavior violation | Defect report, routed by ownership table |
| Inconsistent result, same code | FLAKY classification, investigate, report both outcomes |
| Your own test/fixture is wrong | Fix it yourself — it's test code, not production code |
| Tempted to touch application code | Stop. That's the Iron Law. Report instead. |
