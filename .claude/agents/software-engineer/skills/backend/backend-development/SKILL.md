---
name: backend-development
description: Use when building server-side application logic — layering, dependency injection, configuration, async processing, caching, and concurrency within a single service
---

# Backend Development

## Overview

The practical concerns of building a server-side application within a single service: layering requests through the app, configuration, async/background work, caching, and concurrency safety. For internal structure principles (SOLID, dependency direction), see `software-architecture`; for cross-service coordination, see `distributed-systems-patterns`.

## When to Use

- Structuring how a request flows from the API layer through business logic to persistence
- Deciding what runs synchronously in the request path vs. asynchronously in the background
- Adding caching and needing to reason about invalidation
- Writing code that will run under concurrent requests and needs to avoid races

## Request Flow and Dependency Injection

Inject dependencies (DB connections, external clients, config) rather than constructing them inside business logic — this is what makes the logic testable and lets the same code run against a real DB in production and a fake in tests.

```python
# ❌ Hard-coded dependency, untestable without a real DB
class OrderService:
    def place_order(self, items):
        conn = psycopg2.connect(DATABASE_URL)
        ...

# ✅ Injected dependency
class OrderService:
    def __init__(self, orders: OrderRepository):
        self.orders = orders

    def place_order(self, items):
        ...
```

Most frameworks (FastAPI's `Depends`, Spring's `@Autowired`, NestJS's constructor injection) have a built-in DI mechanism — use the framework's, don't hand-roll a service locator.

## Configuration

- Read configuration from environment variables (or a config file loaded at startup), never hard-code environment-specific values (URLs, credentials, feature flags) in code.
- Validate configuration at startup, not lazily at first use — a missing required config value should fail fast with a clear error, not surface as a confusing runtime error deep in a request handler.
- All API keys/secrets should be optional for local/test startup where the feature they gate isn't required — don't make the whole app fail to boot because an optional integration's key is unset.

## Async / Background Processing

Decide what belongs in the request path vs. background work based on: does the caller need the result synchronously, and how long does it take?

| Pattern | When |
|---|---|
| Synchronous in request path | Caller needs the result immediately, operation is fast (DB write, cache lookup) |
| Fire-and-forget background task | Caller doesn't need to wait (sending a notification email, writing an audit log entry) |
| Queue + worker | Operation is slow/unreliable (calling a flaky third-party API, processing a large file) and needs retry semantics |

For queue-based work, always make the handler idempotent — queues redeliver messages (at-least-once delivery is the norm), so processing the same message twice must be safe.

## Caching

Caching is an invalidation problem first, a performance optimization second. Before adding a cache, know:
- **What invalidates it?** Time-based (TTL) is simplest and safest when slightly-stale data is acceptable. Explicit invalidation (bust the cache key on write) is needed when staleness is unacceptable.
- **What's the failure mode on a cache miss or cache-service outage?** The app should degrade to hitting the source of truth, not fail outright, unless the cache is explicitly required for correctness (rare).

```python
def get_user_profile(user_id: str) -> UserProfile:
    cached = cache.get(f"profile:{user_id}")
    if cached:
        return cached
    profile = db.fetch_profile(user_id)
    cache.set(f"profile:{user_id}", profile, ttl=300)
    return profile
```

## Concurrency Safety

Any code that reads-then-writes shared state (a balance, a counter, inventory) is a race condition unless protected:

```python
# ❌ Race: two concurrent requests can both read the same balance,
# both compute a new value, and the second write clobbers the first
balance = get_balance(account_id)
set_balance(account_id, balance - amount)

# ✅ Atomic at the database level
UPDATE accounts SET balance = balance - %s
WHERE id = %s AND balance >= %s   -- also enforces the invariant atomically
```

Prefer pushing the atomic operation into the database (a single `UPDATE ... WHERE` with a guard condition) over read-modify-write in application code. When application-level locking is unavoidable, scope the lock as narrowly as possible and always include a timeout.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Constructing DB/external clients inside business logic | Inject them; depend on an interface |
| App fails to start because an optional integration's key is unset | Make non-core integrations optional at startup |
| Read-modify-write on shared state without a transaction/guard | Push the atomic operation into the database, or use a transaction with the right isolation level |
| Background job handler isn't idempotent | Make it safe to process the same message twice (queues redeliver) |
| Caching without a defined invalidation strategy | Decide TTL vs. explicit invalidation before adding the cache |

## Quick Reference

| Concern | Default |
|---|---|
| Need a DB/external client in business logic | Inject it, don't construct it inline |
| Config values | Env vars, validated at startup, optional for non-core features |
| Slow or unreliable operation | Queue + worker, idempotent handler |
| Shared counter/balance under concurrency | Atomic `UPDATE ... WHERE` guard, not read-modify-write |
| Adding a cache | Decide invalidation strategy and miss-fallback first |
