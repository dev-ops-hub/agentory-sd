---
name: test-strategy-and-automation
description: Use when writing unit, integration, or API-level tests, setting up mocking/contract tests, or deciding how to structure a test suite for a backend feature
---

# Test Strategy and Automation

## Overview

Practical test-writing patterns for backend code: unit tests, integration tests, API/contract testing, and mocking. For *what kind* of tests a change needs and the test pyramid, see `testing-principles`; for the red/green/refactor discipline, see `test-driven-development`. This skill is about the concrete shape of backend tests once you know what to write.

## When to Use

- Writing unit tests for business logic
- Writing integration tests against a real (or realistically faked) database/external dependency
- Testing an API endpoint end-to-end at the HTTP layer
- Setting up a contract test between a service and its consumer

## Unit Tests: AAA Pattern

Arrange, Act, Assert — keep the three visually separated so a test is scannable at a glance:

```python
def test_place_order_rejects_when_item_out_of_stock():
    # Arrange
    inventory = FakeInventoryService(stock={"SKU1": 0})
    processor = OrderProcessor(inventory, FakePaymentGateway(), FakeOrderRepo())

    # Act
    with pytest.raises(OutOfStockError):
        processor.place_order(customer_id="c1", items=[Item("SKU1", 1)], payment_method="card")

    # Assert
    assert inventory.reservations == []  # nothing was reserved
```

Name tests after the behavior, not the method: `test_place_order_rejects_when_item_out_of_stock`, not `test_place_order_2`.

## API/HTTP-Level Testing

Test through the actual HTTP interface (status code, response shape, headers) rather than calling the handler function directly — this catches routing, serialization, and middleware issues that a direct function call skips.

```python
def test_create_order_returns_201_with_location_header(client):
    response = client.post("/orders", json={"items": [{"sku": "SKU1", "qty": 1}]})
    assert response.status_code == 201
    assert response.headers["Location"] == f"/orders/{response.json()['id']}"
```

Cover, per endpoint: the success case, each distinct validation failure (400/422), the auth failure case (401/403), and the not-found case (404) where applicable.

## Mocking Boundaries

- Mock the **slow or external** dependency (real DB connection, third-party API, network call) — not everything reachable from the code under test.
- A mock's return value should mirror the real dependency's complete shape, not just the fields the current test happens to read — a partial mock passes today and breaks silently when the code starts reading another field from the real response.
- If mock setup is longer than the test's actual logic, or the test only passes because the mock does, that's a signal to switch to an integration test with the real (or an in-memory fake) dependency instead.

```python
# ❌ Partial mock — breaks silently when code starts reading `status`
mock_response = {"id": "ch_123"}

# ✅ Mirrors the real gateway response shape completely
mock_response = {"id": "ch_123", "status": "succeeded", "amount": 5000, "currency": "usd"}
```

## Integration Tests

For code that coordinates multiple collaborators (see `testing-principles` for when this is required, not just nice-to-have), test against a real or realistic dependency for at least the critical paths:

```python
def test_place_order_releases_inventory_when_payment_fails(real_db, fake_payment_gateway):
    fake_payment_gateway.will_decline()
    processor = OrderProcessor(RealInventoryService(real_db), fake_payment_gateway, RealOrderRepo(real_db))

    with pytest.raises(PaymentFailedError):
        processor.place_order(customer_id="c1", items=[Item("SKU1", 2)], payment_method="card")

    # Real DB check: reservation was actually rolled back, not just "the mock was called"
    assert RealInventoryService(real_db).get_stock("SKU1") == original_stock
```

Use a real test database (not mocked) for integration tests that specifically verify persistence/rollback behavior — a mocked repository can't catch a transaction boundary bug.

## Contract Testing

When a service and its consumer evolve independently, a contract test verifies the API shape both sides agree on, without needing the real consumer or provider running:

- **Consumer-driven contract tests** (e.g., Pact-style): the consumer defines the interactions it needs; the provider's test suite replays those interactions against the real provider and verifies it still satisfies them.
- Catches "provider changed the response shape and broke a consumer" at CI time, before a cross-service integration test (or production) would.

## Fixtures and Test Data

- Use factories/builders for test data construction, with sensible defaults overridable per test — avoids every test repeating a 10-field object literal, and keeps tests resilient to adding new required fields later.
- Freeze time explicitly (`freezegun` or equivalent) for any test asserting on a timestamp or expiry — don't let a test depend on wall-clock time.

```python
def test_token_expires_after_15_minutes():
    with freeze_time("2024-01-01 12:00:00"):
        token = issue_token(user_id="u1")
    with freeze_time("2024-01-01 12:16:00"):
        assert is_expired(token)
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Testing the handler function directly, skipping HTTP layer | Test through the real HTTP interface to catch routing/serialization bugs |
| Mock response missing fields the real response has | Mirror the complete real structure |
| Test depends on wall-clock time | Freeze time explicitly |
| Giant mock setup, tiny assertion | Switch to an integration test with a real/fake dependency |
| No test for the failure/rollback path of a multi-step operation | Add at least one — see `testing-principles` |

## Quick Reference

| Testing... | Approach |
|---|---|
| Pure business logic | Unit test, AAA pattern, mock only external boundaries |
| An HTTP endpoint | Test through the real HTTP layer, cover success + each failure class |
| Multi-step coordination with rollback | Integration test with real/fake DB, not a full mock |
| Cross-service API shape | Contract test |
| Anything asserting on time | Freeze time explicitly |
