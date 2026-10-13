---
name: software-architecture
description: Use when designing a module/service's internal structure, reviewing architecture for SOLID/layering violations, or deciding how to separate business logic from infrastructure concerns
---

# Software Architecture

## Overview

Internal application architecture: layering, dependency direction, and SOLID-level design — distinct from system/cloud architecture (service topology, infra) and from `distributed-systems-patterns` (cross-service coordination). Use this skill for "how should this module/service be structured internally."

## When to Use

- Designing a new service or module's internal structure
- Reviewing code for layering violations (business logic reaching into HTTP/DB details, or vice versa)
- Deciding where a piece of logic belongs
- A class or function is hard to test, and the fix is structural, not a better mock

## Clean / Hexagonal Architecture

Core idea: business logic (the domain) has no dependency on infrastructure (HTTP, DB, external APIs). Infrastructure depends on the domain; the domain never imports infrastructure.

```
┌─────────────────────────────────────┐
│   Infrastructure (adapters)          │
│   HTTP handlers, DB repos, API clients│
│              ↓ implements             │
│   ┌─────────────────────────────┐   │
│   │   Application (use cases)     │   │
│   │        ↓ calls                │   │
│   │   ┌───────────────────┐     │   │
│   │   │   Domain (entities, │     │   │
│   │   │   business rules)   │     │   │
│   │   └───────────────────┘     │   │
│   └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

Dependency direction always points inward. The domain defines interfaces (ports); infrastructure implements them (adapters) — this is what makes the domain testable without a real database or HTTP server.

```python
# Domain layer — no imports from infrastructure
class OrderRepository(Protocol):
    def save(self, order: Order) -> None: ...
    def find_by_id(self, order_id: str) -> Order | None: ...

class PlaceOrderUseCase:
    def __init__(self, orders: OrderRepository, payments: PaymentGateway):
        self.orders = orders
        self.payments = payments

    def execute(self, cmd: PlaceOrderCommand) -> Order:
        # pure business logic, testable with in-memory fakes for orders/payments
        ...

# Infrastructure layer — implements the domain's interface
class PostgresOrderRepository:
    def save(self, order: Order) -> None:
        # actual SQL here
        ...
```

## SOLID, Applied Practically

| Principle | Practical check |
|---|---|
| **Single Responsibility** | A class/function changes for one reason. If you describe it with "and," split it. |
| **Open/Closed** | Adding a new case shouldn't require editing existing branches — favor polymorphism/strategy over growing `if/elif` chains for variant behavior. |
| **Liskov Substitution** | A subtype must be usable anywhere the base type is expected, with the same contract — no narrowing preconditions or throwing on inputs the base type accepts. |
| **Interface Segregation** | A caller shouldn't depend on methods it never uses — split a fat interface by consumer. |
| **Dependency Inversion** | High-level logic depends on an abstraction, not a concrete low-level implementation — this is what Clean Architecture's "ports" are. |

A sharp, practical smell test: **a constructor with 7+ parameters, or a class importing from more than ~5 unrelated modules, is a sign it has multiple responsibilities** — split it rather than adding an 8th parameter.

## Troubleshooting Common Violations

| Symptom | Likely cause | Fix |
|---|---|---|
| Domain logic imports a DB driver or HTTP library | Dependency pointing the wrong way | Define an interface in the domain; implement it in infrastructure |
| Can't unit-test business logic without spinning up a DB | Business logic coupled directly to a concrete repository | Depend on a repository interface; inject an in-memory fake for tests |
| A decorator or framework annotation leaks into domain code | Framework concern mixed into business logic | Keep framework wiring (routes, DI registration) in the infrastructure/application layer, not the domain |
| Circular imports between modules | Two modules each depend on the other's concrete type | Extract the shared interface into a third module both depend on |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Putting validation logic in the HTTP handler instead of the domain | Move business-rule validation into the domain/use-case layer; HTTP layer only validates shape (types present, well-formed) |
| Growing a service class to "do everything" over time | Watch constructor parameter count and import count as an early warning; split when it crosses ~5-7 |
| Testing through the real database because "that's how it really works" | Depend on an interface; test the domain with a fake, add a smaller number of integration tests for the real adapter |

## Quick Reference

| Question | Points to |
|---|---|
| Does business logic depend on infrastructure? | Should be: no (dependency inversion) |
| Can I test this without a DB/HTTP server? | Should be: yes, via an interface + fake |
| Does this class change for more than one reason? | If yes, split it |
| Am I adding another `elif` for a new variant? | Consider polymorphism/strategy instead |
