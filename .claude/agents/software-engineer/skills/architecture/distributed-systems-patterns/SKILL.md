---
name: distributed-systems-patterns
description: Use when a system needs to coordinate across multiple services — decomposition boundaries, CQRS, event sourcing, saga/distributed-transaction patterns, or deciding whether distributed complexity is justified at all
---

# Distributed Systems Patterns

## Overview

Patterns for when logic must coordinate across more than one service or process: service decomposition, CQRS, event sourcing, and saga-style distributed transactions. These solve real problems but add real complexity — the most important use of this skill is often deciding *not* to reach for them.

**Do not introduce distributed-system complexity (saga, event sourcing, CQRS, a new service boundary) unless the requirements actually justify it.** A single well-structured service (see `software-architecture`) solves most problems more simply than a distributed one.

## When to Use

- Deciding whether a new piece of functionality should be its own service or a module in an existing one
- A workflow spans multiple services and needs to stay consistent despite partial failures
- Read and write load/shape have diverged enough that one data model no longer serves both well
- An audit trail or "replay what happened" requirement exists

## When NOT to Use

- The system is a single service with moderate load — a modular monolith with clean internal boundaries (`software-architecture`) gets you most of the benefit of "separable" without the operational cost of a second service
- The team doesn't yet have monitoring/tracing in place for a single service — distributed failure modes are much harder to debug without observability already in place
- The driver is "microservices are the modern way to do it," not a specific, present pain the current structure causes

## Service Decomposition

Decompose along business capability boundaries (what the business does), not technical layers (not "the database service" and "the validation service"). A good boundary:
- Owns its own data — no other service reaches directly into its database
- Can be deployed independently without breaking others
- Maps to a bounded context a single team can reason about

**Decomposition checklist before splitting a service:**
- [ ] Does this capability have a genuinely different scaling, deployment, or team-ownership need than the rest?
- [ ] Can it own its data exclusively, or will it need to query across the boundary constantly? (Constant cross-boundary queries are a sign the boundary is wrong.)
- [ ] Is there a plan for what happens when the new service is unreachable? (Timeout, fallback, degraded mode — not just "assume it's up.")

## CQRS (Command Query Responsibility Segregation)

Split the write model (commands, enforces invariants) from the read model (queries, optimized for display). Justified when read and write shapes/scale have genuinely diverged — e.g., writes are normalized transactional records, but reads need a denormalized, pre-joined view for a dashboard.

```
Write side:  Command → Domain model → Event → Write store (normalized)
                                         │
                                         ▼ (projection)
Read side:   Query → Read model (denormalized, optimized for the query shape)
```

**Don't adopt CQRS just to "separate concerns"** — if one data model already serves both reads and writes adequately, CQRS adds a synchronization problem (keeping the read model current) for no real benefit.

## Event Sourcing

Store the sequence of events that happened, not just current state — current state is derived by replaying events. Useful when an audit trail, point-in-time reconstruction, or "why did this change" question is a real requirement.

Core rules:
- **Events are immutable facts.** Never delete or modify a stored event — if something was wrong, append a correcting event.
- **Handlers must be idempotent.** Replaying the same event twice (retry, redelivery) must not double-apply its effect.
- **Correlation IDs** tie related events together across services for tracing a single logical operation.

```python
# Append-only event store, never mutate past events
@dataclass(frozen=True)
class OrderPlaced:
    order_id: str
    customer_id: str
    items: list[LineItem]
    occurred_at: datetime
    correlation_id: str

def apply(state: OrderState, event: OrderPlaced) -> OrderState:
    # pure function: event + prior state -> new state
    ...
```

## Saga Pattern (Distributed Transactions)

When a business operation spans multiple services, each with its own local transaction, and there's no single ACID transaction across all of them: coordinate with a saga that executes a sequence of local transactions and a compensating action for each, to undo prior steps if a later one fails.

Two styles:
- **Orchestration** — a central coordinator calls each step and triggers compensations on failure. Easier to reason about and trace; the coordinator is a single point of complexity.
- **Choreography** — each service reacts to events from the previous step and emits its own; no central coordinator. Scales better organizationally, harder to see the whole flow in one place.

```
Orchestrated saga, happy path:
  Reserve inventory → Charge payment → Create order
Orchestrated saga, payment fails:
  Reserve inventory → Charge payment (FAILS) → Compensate: release inventory
```

**Every step needs a compensating action.** If a step can't be meaningfully undone (e.g., an email already sent), design the saga so that step runs last, after everything undoable has succeeded.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Splitting services along technical layers, not business capability | Decompose by what the business does, not by (DB layer / validation layer / etc.) |
| Adopting CQRS/event sourcing because they sound more "proper" | Only adopt when read/write divergence or audit-trail requirements are real and present |
| A saga step with no compensating action | Design the step order so irreversible actions run last, or add a compensation |
| Treating a remote call like a local one (no timeout, no fallback) | Every cross-service call needs an explicit timeout and failure behavior |
| Choosing choreography for a 3-person team's first distributed system | Start with orchestration — it's easier to debug and trace end to end |

## Quick Reference

| Need | Pattern |
|---|---|
| Split by what changes together, not how it's implemented | Service decomposition by business capability |
| Read/write shape or scale have diverged | CQRS |
| Need audit trail / point-in-time reconstruction | Event sourcing |
| Multi-service operation needs all-or-nothing semantics without a shared transaction | Saga (orchestration first, choreography once the team outgrows it) |
| None of the above pain exists yet | Stay in one service; use `software-architecture` for internal structure |
