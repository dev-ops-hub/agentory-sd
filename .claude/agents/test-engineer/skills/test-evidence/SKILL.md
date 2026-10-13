---
name: test-evidence
description: Use when packaging test execution results into a defensible record - what counts as evidence, how to distinguish VERIFIED from INFERRED, before any QA conclusion is reported
---

# Test Evidence

## Overview

A QA conclusion is only as good as what backs it. This skill is the discipline for *what counts as evidence* and how it's packaged, building directly on the shared `../../shared-skills/verification-before-completion/SKILL.md` discipline (that skill is the general "run it before you claim it" rule shared with every engineering agent; this skill is the QA-specific packaging of that evidence into a reportable record).

## When to Use

- Before reporting any test result (pass, fail, blocked) in a defect report, acceptance check, or release assessment
- Deciding whether a claim ("the suite passes") is actually backed by something you can point to

## The Three Labels

Every claim this agent makes about test outcomes carries one of:

- **VERIFIED** — you ran the command/test/check in this session and are quoting its actual output.
- **INFERRED** — you did not run it directly, but a closely related check that was run supports a reasonable conclusion (e.g., the same code path is exercised by a test that passed for a different scenario). State the inference and what it rests on; don't present it as VERIFIED.
- **NOT VERIFIED** — no evidence exists yet. State this plainly rather than guessing or defaulting to an optimistic label.

Never silently promote INFERRED or NOT VERIFIED to VERIFIED under time pressure, caller insistence, or because "it should be fine." See `../../shared-skills/verification-before-completion/SKILL.md`'s rationalization table — it applies here without modification.

## What Counts as Evidence

| Claim | Acceptable evidence |
|---|---|
| "Tests pass" | Full test command output, this session, showing 0 failures and the count |
| "Bug fixed" | The original failing reproduction, re-run, now passing — not just "code changed" |
| "No regression" | The existing suite's full run, not just the new test |
| "Flaky" | At least 2 observed outcomes (one pass, one fail) with no code change between — a single run is not enough to call something flaky |
| "Acceptance criterion met" | The system actually executed via its real interface, output compared to the stated criterion |
| "Agent delegation completed" | The actual diff/file change, not the agent's self-report alone |

A screenshot, a log line, or a command's exit code is evidence. "I checked and it's fine" is not — it's a claim about evidence that doesn't exist in the report.

## Packaging a QA Report's Evidence

For each test executed as part of a scope:

```
Test ID / name
Command run (verbatim)
Result (pass/fail/blocked)
Relevant output excerpt (not the full noisy log — the lines that prove the result)
Timestamp or session reference (so staleness is checkable)
```

Avoid two failure modes: dumping an entire unfiltered log (buries the evidence that matters) and summarizing with no excerpt at all (unverifiable claim dressed as a report).

## Common Mistakes

| Mistake | Fix |
|---|---|
| "Tests should pass now" after a fix, without re-running | Re-run and quote the output — see `../../shared-skills/verification-before-completion/SKILL.md` |
| Calling something flaky from a single failure | Need at least 2 outcomes (pass + fail) with no code change between to support FLAKY |
| Reporting a defect's fix as verified from the author's claim | Re-run the specific original reproduction yourself |
| Evidence section is a wall of raw log output | Excerpt the lines that actually prove the claim |

## Quick Reference

| Label | When to use |
|---|---|
| VERIFIED | You ran it this session, quoting real output |
| INFERRED | A related, already-run check supports the conclusion — say what it rests on |
| NOT VERIFIED | No evidence yet — say so, don't guess |
