---
name: problem-decomposition
description: Use when a request is ambiguous, too large for one change, or mixes several concerns, before designing or writing any code
---

# Problem Decomposition

## Overview

Breaking an ambiguous or oversized request into clear, independently-tractable pieces before any design or code gets written. Applies to any engineering role when a request doesn't arrive pre-scoped.

## When to Use

- A request names a goal but not a concrete scope ("make the app faster", "add caching", "fix the checkout bug")
- A request bundles multiple unrelated concerns in one ask
- A task feels too large to start on directly — that feeling is a signal to decompose, not a signal to start guessing

## The Decomposition Pass

1. **Restate the goal in one sentence.** If you can't, the request isn't understood yet — ask, don't assume.
2. **List the unknowns.** What would change your approach if you knew it? (Scale, existing constraints, who's affected, what's explicitly out of scope.) Only ask about unknowns that actually change the approach — don't ask questions whose answer wouldn't move the design.
3. **Split by independence, not by size.** Two pieces are separable if one can be built, tested, and shipped without waiting on the other. A task that's "small" but blocks everything else isn't a good first slice; a "big" piece that's fully independent might be.
4. **Order by risk and dependency, not convenience.** Do the piece that would invalidate the rest of the plan first (the riskiest assumption, the piece most likely to reveal a wrong design), not the easiest piece.
5. **Name what's explicitly out of scope.** An unscoped request left implicit tends to grow silently; writing "not doing X in this change" is cheap and prevents scope creep later.

## Example

Request: "Make the app faster."

**Bad decomposition:** Start optimizing the first slow-looking thing you find.

**Good decomposition:**
1. Restate: "Reduce perceived load time for [specific flow], or reduce server-side latency for [specific endpoint]?" — these are different problems; ask which, or state the assumption if asking isn't practical.
2. Unknowns that matter: current measured latency, the specific user-facing symptom that prompted the request, whether this is about one slow path or general perf.
3. Split: profiling (find what's actually slow) is separable from fixing any one bottleneck — profile first, don't guess-and-fix.
4. Order: profile → pick the highest-impact bottleneck → fix → re-measure, rather than fixing the first thing noticed.
5. Out of scope: note explicitly if, e.g., database schema changes are out of scope for this pass.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Starting to code before the goal is stated in one clear sentence | Restate the goal; if you can't, ask |
| Treating "it feels big" as a reason to start anywhere | Split by independence and risk, not by what's easiest to start |
| Asking clarifying questions whose answer wouldn't change the approach | Only ask what actually moves the design |
| Leaving scope boundaries implicit | Write down what's explicitly out of scope for this change |
| Decomposing by file/layer instead of by independently-shippable behavior | Split so each piece can be built and verified on its own |

## Quick Reference

| Signal | Action |
|---|---|
| Can't restate the goal in one sentence | Ask before designing |
| Request bundles unrelated concerns | Split into separate changes |
| Unknown would change the approach | Ask it; skip unknowns that wouldn't |
| Task feels too large to start | Split by independence and risk, not size |
