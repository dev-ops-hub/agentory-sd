---
name: test-strategy
description: Use when planning how a feature, sprint, or release should be tested overall - which test levels, which risks drive depth, and what's safe to defer under a deadline
---

# Test Strategy

## Overview

The top-level QA planning pass: given a feature or release scope, decide what needs testing, at what depth, and in what order, before writing any test case. This sits above `test-case-design` (which designs the individual cases) and `testing-principles` (shared skill — the test pyramid and mocking-boundary theory this strategy applies).

## When to Use

- Starting QA work on a new story, sprint, or release
- Scoping how much testing a change needs under a real deadline
- Deciding whether a feature needs E2E coverage, or integration/unit is sufficient

## Risk-Based Prioritization

Not every path gets equal depth. Prioritize by **likelihood × impact**:

| Signal | Raises priority |
|---|---|
| Touches money, positions, or trade records | Always highest — see this project's constitution Principle IV/V as the concrete example of why |
| New code, not a well-trodden path | Higher — unexercised code has unknown failure modes |
| Complex branching or multi-step coordination | Higher — more paths through the code, more chances for a missed interaction |
| High usage / on the critical user journey | Higher — a bug here is seen by everyone, not an edge case |
| Pure refactor with existing coverage | Lower — the regression suite already protects this |
| Cosmetic/copy-only change | Lower — functional risk is minimal |

## Choosing Test Levels

Apply the shared `testing-principles` pyramid to the feature's actual shape, not a fixed ratio:

- A pure validation function → unit tests carry almost all the confidence.
- A multi-step coordinator (e.g., reserve → charge → persist) → unit tests for branches, plus at least one integration test for the failure/rollback path.
- A cross-component user journey a user actually walks through end-to-end → one E2E test, sparingly — see `../../shared-skills/e2e-browser-testing/SKILL.md`.

Prefer the lowest test level that gives sufficient confidence. A feature doesn't need an E2E test merely because it has a UI — it needs one when the user-visible journey crossing multiple components is the actual risk.

## Ambiguity and Gaps

Before designing test cases, read the requirement/acceptance-criteria source (see `../requirements-test-analysis/SKILL.md`) and flag:

- Acceptance criteria with no observable pass/fail condition
- A requirement that doesn't say what should happen on the failure/error path
- Conflicting statements between the PRD, the sprint spec, and the constitution

Flag these as Gaps to the owning product role rather than guessing a behavior and testing your guess.

## Scoping Under a Deadline

A deadline changes what gets deferred, never what gets silently dropped:

**Safe to defer:**
- Full E2E coverage of secondary (non-critical-path) journeys
- Performance/load testing, unless the PRD/constitution already states a threshold (see Performance note below)
- Exhaustive boundary-value enumeration beyond the known-risky boundaries

**Never safe to cut:**
- A test for a known or suspected defect surfaced during this pass
- The failure/rollback path of any multi-step operation touching money or persisted state
- The specific scenario the ticket/PR exists to fix
- Coverage for a constitution MUST rule that applies to the scope

## Performance Testing — Conditional

Only plan performance/load testing when the PRD or constitution states an actual threshold (response time, throughput, concurrent-user count). Inventing a pass/fail number that isn't anywhere in the requirements is not test strategy, it's a guess dressed as one. When a real threshold exists, name the appropriate tool for this stack (k6 pairs naturally with a FastAPI backend) and design load/stress/spike/endurance tests against that stated number — never against an assumption.

## Security — Functional Only

This strategy may include security-related *functional* acceptance criteria (unauthorized requests rejected, role-based access enforced) using `secure-engineering`. A full threat model, OWASP sweep, or dependency vulnerability assessment is `security-auditor`'s job — name it as a dependency in the strategy rather than attempting it here.

## Output

A test strategy states, per scope: the risk ranking, which test levels apply and why, what's explicitly deferred and why that's safe, and any Gaps blocking test-case design. Feed this into `../test-case-design/SKILL.md` next.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Treating "has a UI" as sufficient reason for an E2E test | Reserve E2E for genuinely cross-component critical journeys |
| Applying the same depth to a cosmetic change and a money-path change | Rank by likelihood × impact, concentrate depth where it matters |
| Inventing a performance threshold to have something to test | Only test against a stated PRD/constitution number; otherwise flag the gap |
| Treating "deadline" as license to skip a known-bug test | Known bugs always get a test; breadth is what gets deferred |

## Quick Reference

| Question | Where to look |
|---|---|
| What test levels does this feature need? | `testing-principles` (shared) applied via the risk table above |
| What should I actually test? | `../requirements-test-analysis/SKILL.md` next |
| How do I write the test cases? | `../test-case-design/SKILL.md` next |
| Is this safe to defer? | The deadline table above |
