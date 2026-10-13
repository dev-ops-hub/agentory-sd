---
name: code-review
description: Use when reviewing a pull request or diff, or before requesting review on your own change — covers what to check, how to grade findings, and how to phrase comments
---

# Code Review

## Overview

A structured review pass: what to check, in what order, and how to grade and phrase findings so review is thorough without being either a rubber stamp or needless friction. Applies when reviewing someone else's change and as a self-review pass before opening a PR.

## When to Use

- Reviewing a pull request or diff, from any role
- Self-reviewing before requesting review
- The author says "it's basically a formality" or there's deadline pressure — review quality should not change with social or time pressure; a change touching money, auth, or data integrity gets the same scrutiny in five minutes as in fifty

## Review Passes

Work in this order — each pass catches a different class of problem, and later passes are wasted effort if an earlier one reveals the change is fundamentally wrong:

1. **Intent** — does the diff do what the PR description/ticket says? Is anything missing or extra?
2. **Correctness** — logic errors, off-by-one, wrong operator, inverted condition, dropped error check, race conditions, incorrect error handling.
3. **Security** — see the checklist below; always applies, not just to code labeled "security-sensitive."
4. **Data integrity** — for anything touching money, state transitions, or persisted records: does this change what gets written, and is that change correct and atomic?
5. **Tests** — do tests exist for the new behavior, and do they test real behavior rather than mocks (see `test-driven-development`'s `writing-good-tests.md`)?
6. **Readability/maintainability** — naming, structure, duplication. Lowest priority; don't block a correct change on style alone.

## Correctness & Security Checklist

Run this against every diff, regardless of how it's framed by the author:

- [ ] Every external input (user input, API response, DB row, LLM output) validated before use
- [ ] No string-interpolated SQL/shell/command construction — parameterized queries, `execFile`-style argument arrays
- [ ] No secrets, tokens, or credentials in logs, error messages, or committed files
- [ ] Error paths don't silently succeed (e.g., catching an exception and returning a success-shaped value)
- [ ] Changed error-handling preserves the original contract for existing callers (same exception type, same success/failure shape) unless the PR explicitly changes the contract everywhere it's used
- [ ] Money/quantity values use integer or Decimal arithmetic, not floating point
- [ ] Concurrent/duplicate requests can't double-execute a state change (idempotency, locking, or a unique constraint)
- [ ] New dependency is from a trusted source and pinned

## Grading Findings

Grade every finding so the author knows what blocks merge:

| Grade | Meaning |
|---|---|
| **P0 / Blocking** | Breaks correctness, security, or data integrity. Must fix before merge. |
| **P1** | Real problem, but mergeable with a fast follow-up (file a ticket, don't just drop it). |
| **P2 / P3** | Style, naming, minor readability. Suggest, don't block. |

Social signals ("Priya already looked at it," "we're almost out of time," a friendly tone) are not evidence about the code — they can soften *how* you phrase a comment, never *whether* a P0 gets raised.

## Phrasing Comments

- State the problem and a concrete fix, not just "this is wrong."
- Prefer "this allows X — fix by Y" over "why did you do this?"
- For a blocking finding under real time pressure, offer the narrowest fix that unblocks merge (e.g., "cut this one function from the PR" vs. "rewrite the whole module") rather than only naming the ideal fix.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Approving because a deadline is close | Grade on the merits; offer a narrower scope to still hit the deadline instead of lowering the bar |
| Treating "someone already looked at it" as reducing your own scrutiny | Review as if you're the only reviewer — a prior pass is not evidence, it's a claim |
| Reviewing style before correctness | Work top-down through the review passes above |
| Flagging everything at the same severity | Grade P0–P3 so the author knows what's actually blocking |
| Reviewing the diff in isolation from its callers | Check who calls the changed function and whether its contract changed under them |

## Quick Reference

| Check | Pass |
|---|---|
| Does it do what it claims? | Intent |
| Logic errors, dropped checks | Correctness |
| Injection, secrets, auth | Security |
| Money/state correctness, atomicity | Data integrity |
| Real tests for new behavior | Tests |
| Naming, structure | Readability (lowest priority) |
