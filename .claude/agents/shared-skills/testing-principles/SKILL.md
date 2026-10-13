---
name: testing-principles
description: Use when deciding what level and shape of tests a change needs — the test pyramid, when mocking everything is and isn't sufficient, and how to scope a test plan under a deadline
---

# Testing Principles

## Overview

Role-agnostic framing for deciding *what kind* of tests a change needs, before writing any of them. For the test-first discipline itself (red/green/refactor on an individual function), see `test-driven-development`. This skill is about test *strategy and shape* — the pyramid, mocking boundaries, and what a deadline can and can't cut.

## When to Use

- Planning what to test for a class/module that integrates with several external collaborators (a DB, a payment gateway, another service)
- Deciding whether "mock everything, write N unit tests" is actually sufficient for a given piece of code
- Scoping a test plan against a real deadline — deciding what's safe to defer vs. what isn't

## The Test Pyramid

```
      /\
     /E2E\        few — slow, brittle, highest confidence per test
    /------\
   /Integr. \     some — real collaborators (or one real + rest mocked),
  /----------\    catches integration bugs unit tests can't see
 /   Unit     \   many — fast, isolated, one behavior each
/--------------\
```

Each layer catches a different class of bug. A pile of unit tests with every collaborator mocked is strong on *this function's internal logic* and blind to *how the pieces interact* — wrong call order, a result from one collaborator misinterpreted by the next, a failure path that isn't actually reachable the way the mock assumes.

## When "Mock Everything" Is and Isn't Enough

Mock-heavy unit tests are the right primary tool when:
- The collaborators have a stable, well-understood contract (e.g., a repository interface you control)
- You're testing branching logic *within* the unit (different return values → different code paths)

They are **not sufficient alone** when the unit's job is coordinating multiple external systems and the risk is in the coordination itself — e.g., a function that reserves inventory, then charges a payment, then creates an order record. There, mocking every collaborator proves each call *happens*, but not:
- Whether a partial failure (charge succeeds, order-create fails) leaves the system in a consistent state
- Whether a multi-step operation partially completes and leaves orphaned side effects (e.g., some items reserved, others not, on a failure mid-loop)
- Real serialization/contract mismatches with the actual collaborator (a mock that returns whatever you tell it to can't catch "the real service returns a different shape than I assumed")

For that class of code, add at least one integration-style test exercising the real failure-and-partial-rollback path, even if the rest of the suite stays mock-based.

## Scoping Under a Deadline

A deadline is a reason to prioritize, not a reason to drop correctness-critical coverage:

**Safe to defer past a near-term deadline:**
- Full end-to-end tests against a real environment
- Performance/load testing
- Exhaustive edge-case enumeration beyond the known-risky ones

**Not safe to cut, regardless of deadline:**
- A test for a known or suspected bug in the code under test (if review surfaces one, it needs a test, not just a mental note)
- At least one test covering the failure/rollback path of a multi-step operation that touches money, inventory, or any persisted state
- The specific scenarios the ticket or PR description calls out as the reason the change exists

## Common Mistakes

| Mistake | Fix |
|---|---|
| "Mock everything, 5-6 tests, done" for a multi-system coordinator | Add the failure/partial-rollback path as a real (or realistically faked) integration test |
| Treating a Friday deadline as license to skip a known-bug test | Known bugs get a test regardless of deadline; defer breadth, not correctness |
| Writing tests only for the happy path | Enumerate at least: happy path, each distinct failure mode, and one boundary case |
| Equating "high test count" with "sufficient coverage" | Coverage is about which failure modes are caught, not how many test functions exist |

## Quick Reference

| Code shape | Primary test layer |
|---|---|
| Pure function, internal branching logic | Unit, mocked collaborators |
| Multi-step coordinator (reserve → charge → persist) | Unit for branches + integration for the failure/rollback path |
| Cross-service contract | At least one test against the real contract, not just a mock |
| User-facing critical flow | At least one E2E, sparingly |
