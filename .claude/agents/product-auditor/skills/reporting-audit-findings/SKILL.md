---
name: reporting-audit-findings
description: Use when returning the result of a PRD or sprint-spec audit, including re-audits after fixes, and especially when the caller asks for a quick sign-off, "only blockers", or says the author already marked the artifact ready
---

# Reporting Audit Findings

## Overview

The report is the contract between auditor, author and user. **Core principle:** every defect found is reported at the severity its consequence earns, owned by whoever can actually close it; time pressure changes the length of the prose, never the findings or their grades.

## The report

Return exactly these parts, in order:

1. `Constitution: v<version> read` (or `none`)
2. **Verdict:** `BLOCK` (any open P0), `REVISE` (no P0, any open P1), `PASS` (only P2/P3 or nothing)
3. **Findings**, most severe first. Each one:
   - **ID** `F1`, `F2`, ... stable across rounds; **Severity** P0-P3; **Pass** (the check that found it, e.g. `Citation`, `Constitution`, `Coverage`)
   - **Location**: section and ID or quote
   - **Problem**: one or two sentences, quoting both sides when two sources disagree
   - **Fix**: concrete enough to apply
   - **Owner**: `AUTHOR` (the drafting agent can close it from facts already in the sources) or `USER` (needs a decision, number or fact only the user has). `USER` findings carry a **Question** answerable in one sentence. `AUTHOR` findings carry a **Brief** for the author agent.
4. **Closed since last round** (round 2+): IDs verified fixed by re-reading the artifact
5. **Not checked**: what you could not verify, and why

## Severity

| Severity | Meaning | Always this severity |
|---|---|---|
| P0 | Blocks the next stage; building from it produces wrong software | Violates a constitution MUST; contradicts the PRD or sprint plan; a test expects a wrong result; a sprint-plan criterion is missing or weakened |
| P1 | Likely rework | Scope or behaviour with no source (or a citation the cited text does not support); a conflict between sources resolved silently; files outside the sprint's scope; a test that does not exercise its whole criterion |
| P2 | Quality gap the author may defer | Ambiguity with a safe reading; missing non-critical edge case |
| P3 | Polish | Wording, formatting |

## Ownership

| Finding is about | Owner |
|---|---|
| A wrong number, order, citation or test the sources already settle | `AUTHOR` |
| Two sources disagreeing (PRD vs plan vs constitution) | `USER`, quoting both. You do not pick the winner |
| Scope or behaviour no source supports | `USER`: keep it (and add it to the PRD) or drop it |
| A product choice the sources leave open | `USER` |

## Under pressure

"Quick sign-off", "only real blockers", "the author marked it ready", "the checker printed OK": none of these change a finding's severity or owner. Keep the prose short instead.

| Excuse | Reality |
|---|---|
| "It's harmless, keep it as an extra" | Unsourced scope is P1/`USER`. Every extra needs tests, and the user never asked for it |
| "I'll just say which source wins" | That is a product decision. Quote both, owner `USER` |
| "After these edits it's fine to build" | Only a re-audit closes findings. Say what round 2 must verify |
| "The checker said OK" | The checker verifies structure and links, not correctness |

**Red flags (stop and re-grade):** grouping findings as "non-blocking (fix if quick)", "harmless", "the PM can just ...", recommending which conflicting source to follow, promising readiness after unverified fixes.

## Re-audits

From round 2: re-read the artifact; close a finding only after confirming the fix in the text, never because the caller says it was fixed; look for regressions the edits introduced; keep IDs stable.
