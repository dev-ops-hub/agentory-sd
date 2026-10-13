---
name: integration-patterns
description: Use when integrating with a third-party API or another service — idempotency, retries, webhook handling, and circuit-breaker patterns at the code level
---

# Integration Patterns

## Overview

Code-level resilience patterns for integrating with external services and third-party APIs: idempotency, retries, webhook handling, and circuit breakers. This is the application-code view of resilience — contrast with the platform/mesh-level version of circuit breakers and retries (Istio, service mesh config), which is a DevOps concern, not this skill's.

## When to Use

- Calling a third-party API (payment gateway, email provider, any external service) from application code
- Receiving webhooks from a third party
- A flaky dependency needs to not cascade into your own service's failure
- Designing a retry strategy for a network call

## Idempotency

Any operation with a real-world side effect (charging a card, sending a notification, creating an order) that might be retried — by your own retry logic, a client's retry, or a redelivered webhook — needs an idempotency key so a retry doesn't duplicate the effect.

```python
def charge_customer(customer_id: str, amount_cents: int, idempotency_key: str) -> ChargeResult:
    existing = charge_store.find_by_idempotency_key(idempotency_key)
    if existing is not None:
        return existing  # already processed; return the original result, don't recharge

    result = payment_gateway.charge(customer_id, amount_cents, idempotency_key=idempotency_key)
    charge_store.save(idempotency_key, result)
    return result
```

Many payment/API providers (Stripe, etc.) accept an idempotency key natively — pass your own generated key through to them so even a network timeout on *your* side (where you don't know if the request landed) is safe to retry.

## Webhook Handling

- **Verify the signature** on every incoming webhook using the provider's documented scheme (usually an HMAC over the raw body with a shared secret) before processing anything in the payload — an unverified webhook endpoint lets anyone POST fake events.
- **Process exactly once despite at-least-once delivery.** Providers redeliver webhooks on timeout/no-200-response — store a processed-event-ID record and check it before acting, inside the same transaction as the side effect (a "durable inbox" pattern), so a redelivered event is a no-op rather than a double-apply.
- **Respond fast, process async if slow.** Return `200` as soon as the webhook is durably recorded; do slow processing (sending confirmation emails, updating multiple systems) in a background job, not synchronously in the webhook handler — most providers retry aggressively on timeout, which multiplies load exactly when something's already slow.

```python
def handle_webhook(raw_body: bytes, signature_header: str) -> Response:
    if not verify_signature(raw_body, signature_header, WEBHOOK_SECRET):
        return Response(status=400)

    event = parse_event(raw_body)
    with db.transaction():
        if inbox.already_processed(event.id):
            return Response(status=200)  # redelivery, no-op
        inbox.mark_processed(event.id)
        apply_event_effect(event)  # same transaction: effect and dedup record are atomic

    return Response(status=200)
```

## Retries

- **Only retry what's actually retryable.** A `429`/`503`/network timeout is often retryable; a `400`/`422` (your request was wrong) is not — retrying it just repeats the same failure.
- **Exponential backoff with jitter**, not a fixed interval — a fixed retry interval across many clients synchronizes retries into further load spikes ("thundering herd").
- **Cap total retries and total elapsed time.** An unbounded retry loop against a truly-down dependency ties up resources indefinitely.

```python
import random
import time

def call_with_retry(fn, max_attempts=4, base_delay=0.5):
    for attempt in range(max_attempts):
        try:
            return fn()
        except RetryableError:
            if attempt == max_attempts - 1:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 0.25)
            time.sleep(delay)
```

## Circuit Breaker (Code-Level)

When a dependency is failing consistently, stop calling it for a cooldown period instead of letting every request pay the timeout cost and pile up — fail fast instead.

```
CLOSED (normal) --[failure rate exceeds threshold]--> OPEN (fail fast, no calls)
OPEN --[cooldown elapses]--> HALF_OPEN (allow one trial call)
HALF_OPEN --[succeeds]--> CLOSED
HALF_OPEN --[fails]--> OPEN
```

This belongs in application code when the dependency is called directly from your service (an SDK/HTTP client wrapper). If a service mesh or API gateway already provides circuit breaking at the infrastructure level, don't duplicate it in application code — know which layer owns it for a given deployment, and ask rather than assume if unclear.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Retrying a `400`/validation error as if it were transient | Only retry genuinely retryable failures (timeouts, `429`, `503`) |
| Fixed-interval retries across many clients | Exponential backoff with jitter |
| No idempotency key on a side-effecting external call | Generate and pass one; check for it on your own side too |
| Processing a webhook's side effect without a dedup check | Durable inbox pattern: dedup check and side effect in one transaction |
| Synchronous slow processing in the webhook handler | Record and ack fast; do slow work in a background job |
| Unbounded retry loop | Cap attempts and total elapsed time |

## Quick Reference

| Situation | Pattern |
|---|---|
| Side-effecting call that might retry | Idempotency key |
| Incoming webhook | Verify signature → durable inbox dedup → ack fast → process async if slow |
| Transient failure (timeout, 429, 503) | Exponential backoff + jitter, capped attempts |
| Dependency failing consistently | Circuit breaker — fail fast during cooldown |
