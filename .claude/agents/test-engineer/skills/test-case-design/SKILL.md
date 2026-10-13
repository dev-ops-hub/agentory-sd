---
name: test-case-design
description: Use when designing concrete test cases from testable requirements - applying boundary value analysis, equivalence partitioning, decision tables and error guessing so coverage goes beyond the happy path
---

# Test Case Design

## Overview

Turns a testable requirement (from `../requirements-test-analysis/SKILL.md`) into concrete test cases using recognized test-design techniques. The goal is systematic coverage, not a pile of happy-path variations.

## When to Use

- A testable acceptance criterion exists and needs concrete cases
- Reviewing an existing test suite for coverage gaps beyond the happy path
- Designing API test cases (pairs with `../../shared-skills/test-strategy-and-automation/SKILL.md` for the implementation shape)

## Techniques

**Equivalence partitioning** — group inputs that should behave the same way, test one representative per group rather than every possible value.

**Boundary value analysis** — the bugs cluster at the edges. For any bounded value, test:

```
minimum
maximum
just below minimum
just above maximum
one above minimum
one below maximum
```

Example — this project's quantity rule ("finite, > 0, ≤ 1,000,000 shares, ≤ 4 decimal places", constitution Principle IV): test 0 (rejected), 0.00001 (rejected, too many decimals), 0.0001 (accepted, boundary), 1,000,000 (accepted, boundary), 1,000,000.0001 (rejected, over max), a negative value (rejected), `NaN`/`Infinity` (rejected, not finite).

**Decision tables** — when a result depends on the combination of several independent conditions, enumerate the combinations rather than testing each condition in isolation (which misses interaction bugs).

| Price stale? | Has position? | Confirm pressed? | Expected |
|---|---|---|---|
| Yes | — | — | 400 "price is stale" |
| No | No | Yes | Trade executes |
| No | Yes | Yes | Trade executes, position updates |
| No | — | No | No state change |

**State transition testing** — for anything with a defined state machine (e.g., a proposal's `pending`/`confirmed`/`rejected`/`expired` lifecycle), test every legal transition and at least the obviously-tempting illegal ones (confirming an already-confirmed proposal, rejecting an expired one).

**Pairwise/combinatorial testing** — when many independent parameters combine (filters, sort order, pagination), pairwise testing covers all 2-way interactions without the combinatorial explosion of full coverage.

**Error guessing** — informed by experience: null/empty/missing fields, duplicate submissions, Unicode/special characters in text fields, concurrent requests to the same resource, a dependency that's slow or down.

**Exploratory testing** — see `../exploratory-testing/SKILL.md` for unscripted investigation once scripted cases are designed.

## Minimum Coverage Checklist

Every meaningfully risky feature should consider, not just the happy path:

```
valid input
invalid input
missing/null input
minimum boundary
maximum boundary
just below minimum
just above maximum
duplicate submission
unexpected state (e.g. action on an object in a terminal state)
dependency failure (DB down, upstream API down/slow/timeout)
permission failure (wrong role, no session)
concurrency (two requests racing on the same resource)
```

Not every feature needs every row — risk-rank per `../test-strategy/SKILL.md`, but a feature touching money, state transitions, or persisted records needs the concurrency and dependency-failure rows at minimum.

## API Test Cases

For an API surface, inspect OpenAPI/Swagger/route definitions and cover at minimum: happy path, validation failures (400/422) per field, auth/authz failures (401/403), not-found (404), response/error contract shape, idempotency (does repeating the same request twice do the right thing), and pagination/filtering edge cases where applicable. See `../../shared-skills/test-strategy-and-automation/SKILL.md` for how to implement these at the HTTP layer rather than calling handlers directly.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Only testing values comfortably inside a valid range | Add the four boundary values: just-below-min, min, max, just-above-max |
| Testing conditions independently when they interact | Use a decision table once two or more conditions jointly determine the outcome |
| Treating "idempotent" as untested until it's explicitly in the ticket | Idempotency gets a test whenever a state-changing action could plausibly be retried or double-submitted |
| No test for an illegal state transition | State machines get negative-path tests, not just the happy transitions |

## Quick Reference

| Situation | Technique |
|---|---|
| A single bounded numeric/length value | Boundary value analysis |
| Result depends on 2+ independent conditions | Decision table |
| Object has defined states | State transition testing |
| Many independent filter/sort params | Pairwise testing |
| "What would a user actually try that I haven't thought of" | Error guessing + exploratory testing |
