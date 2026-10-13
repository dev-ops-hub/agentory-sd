---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports done → Check VCS diff/output → Verify independently → Confirm or report gap
❌ "Agent said it's done" (trusting without verification)
```

## Why This Matters

Claims without verification are often wrong:
- "Should work" → doesn't work
- "Tests pass" (not run) → tests fail
- "Linter clean" (not compiler) → compilation errors
- "Agent completed" (not verified) → agent didn't actually make changes

**Cost of verification:** 30 seconds to run a command.
**Cost of skipping it:** Hours of downstream debugging, false reports to users, broken builds discovered later.

## Integration with Other Practices

**Test-Driven Development:** TDD's "watch it fail, watch it pass" IS verification before completion applied to individual tests. This skill extends that discipline to the entire task: builds, requirements, agent delegation, final claims.

**Systematic Debugging:** Don't claim a bug is fixed without reproducing the original failure, applying the fix, and confirming the failure no longer occurs.

## When Delegating to Agents

Subagent reports "task complete" or "tests passing"? That's a claim, not evidence.

**Before relaying agent success to the user:**
1. Check actual VCS diff/status for claimed file changes
2. Run the verification command yourself if feasible
3. Only relay success after independent confirmation

Agent reports are starting points for verification, not substitutes for it.

## Final Rule

```
Claim of success → verification command run THIS message → output confirms claim
Otherwise → not verified, say so
```

No exceptions without the user's explicit permission to proceed unverified.
