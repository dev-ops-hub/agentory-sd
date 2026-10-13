---
name: clean-code-and-refactoring
description: Use when naming is unclear, a function is doing too much, reviewing code for SOLID smells, or planning a refactor of existing/legacy code
---

# Clean Code and Refactoring

## Overview

Code-quality fundamentals — naming, function size, error handling — and the discipline of refactoring existing (including legacy) code safely. For architectural-level structure (layering, dependency direction), see `software-architecture`; this skill is about the code itself, one function/class at a time.

## When to Use

- Writing or reviewing code and something feels "off" but hard to name
- A function has grown too large or does more than one thing
- Planning to change behavior in code with poor or no test coverage
- Migrating/modernizing a legacy pattern (old framework version, deprecated library)

## Naming

- A name should make a comment unnecessary. If you need a comment to explain what a variable holds, the name is wrong.
- Avoid abbreviations that save keystrokes but cost comprehension (`usr`, `tmpCfg`) — the cost of a slightly longer name is paid once; the cost of an unclear one is paid by every future reader.
- Boolean names should read as a predicate: `is_active`, `has_permission`, not `active_flag`, `permission`.
- Function names describe what they do, not how: `send_welcome_email`, not `insert_row_and_call_api`.

## Function Size and Responsibility

A function doing one thing is easy to name, easy to test, and easy to read top-to-bottom without scrolling. Signals a function has grown past one responsibility:
- The name needs "and" to describe it
- It has more than ~3 levels of nesting
- It mixes levels of abstraction (business logic interleaved with low-level string formatting or raw SQL)

```python
# ❌ Does three things: fetch, validate, and format
def process_order(order_id):
    order = db.query(f"SELECT * FROM orders WHERE id={order_id}")  # also: SQL injection
    if order.status != "pending":
        raise ValueError("not pending")
    return f"Order #{order.id}: {order.total:.2f}"

# ✅ Each function does one thing
def get_pending_order(order_id: str) -> Order:
    order = order_repo.find_by_id(order_id)
    if order.status != OrderStatus.PENDING:
        raise InvalidOrderStateError(order_id, order.status)
    return order

def format_order_summary(order: Order) -> str:
    return f"Order #{order.id}: {order.total:.2f}"
```

## Error Handling

- Fail with a specific exception type, not a bare `Exception` or a generic error string — callers need to distinguish "not found" from "invalid input" from "external service down."
- Don't swallow an exception into a success-shaped return value (see `secure-engineering` and `code-review` — this is a correctness issue as much as a style one).
- Validate preconditions early and return/raise immediately (guard clauses) rather than nesting the "happy path" inside multiple conditionals.

```python
# ❌ Deeply nested happy path
def charge(order):
    if order is not None:
        if order.status == "pending":
            if order.total > 0:
                return gateway.charge(order.total)
    return None

# ✅ Guard clauses, flat happy path
def charge(order):
    if order is None:
        raise ValueError("order required")
    if order.status != "pending":
        raise InvalidOrderStateError(order.status)
    if order.total <= 0:
        raise ValueError("order total must be positive")
    return gateway.charge(order.total)
```

## SOLID Smells (Quick Checklist)

See `software-architecture` for the full SOLID reference; the fast version for a code-review pass:
- [ ] Constructor with 7+ parameters → likely doing too much, split it
- [ ] A new `if`/`elif` branch added for every new variant of something → consider polymorphism
- [ ] A class imports from many unrelated modules → multiple responsibilities
- [ ] A subclass that throws on a method the base class accepts → Liskov violation

## Refactoring Legacy / Low-Coverage Code

The core risk in refactoring code without tests is that you can't tell if you broke it. The standard safe approach:

1. **Characterization tests first.** Before changing anything, write tests that capture *current* behavior (even if that behavior seems wrong) — this gives you a safety net to refactor against. Fix the actual bug as a separate, deliberate step afterward, not accidentally during refactoring.
2. **Strangler fig for larger migrations.** Route an increasing share of traffic/calls to the new implementation while the old one still exists, rather than a single big-bang rewrite — lets you catch divergence early and roll back cheaply.
3. **One refactor at a time, verified green between each.** Rename, then extract, then simplify — not all three in one diff with the tests run only at the end. This is `test-driven-development`'s refactor step applied at a larger grain.
4. **Always have a rollback plan** for a legacy migration — know how to revert to the old path if the new one misbehaves in production.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Refactoring and changing behavior in the same commit | Separate "restructure, behavior unchanged" from "fix the bug" into distinct steps |
| Refactoring legacy code with no tests at all | Write characterization tests first, then refactor |
| Big-bang rewrite of a legacy system | Strangler fig: migrate incrementally, old and new coexist during transition |
| A name requiring a comment to explain it | Rename instead of commenting |
| Catching a broad exception and returning a generic failure | Catch specific exceptions; preserve the distinction callers need |

## Quick Reference

| Signal | Action |
|---|---|
| Function name needs "and" | Split into separate functions |
| Deeply nested happy path | Convert to guard clauses |
| No tests, need to change behavior | Characterization tests first |
| Large legacy rewrite | Strangler fig, incremental |
| Constructor with 7+ params | Likely multiple responsibilities — split |
