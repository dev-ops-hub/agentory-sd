---
name: fastapi
description: Use when building or reviewing a FastAPI application — dependency injection, Pydantic request/response models, async route handlers, and testing with pytest-asyncio
---

# FastAPI

## Overview

FastAPI-specific patterns on top of the `python` language skill: dependency injection via `Depends`, Pydantic models for request/response validation, async route handlers, and testing conventions.

## When to Use

- Building or reviewing a FastAPI route, dependency, or app structure
- Setting up request/response validation
- Testing a FastAPI app with async test clients
- Wiring a database session or other per-request resource

## Dependency Injection with `Depends`

FastAPI's `Depends` is the framework's built-in DI mechanism — use it rather than importing a global client/session directly into a route handler, so handlers stay testable with an overridden dependency.

```python
from fastapi import Depends, FastAPI

app = FastAPI()

def get_db_session():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()

@app.get("/orders/{order_id}")
async def get_order(order_id: str, db: Session = Depends(get_db_session)):
    order = order_repo.find_by_id(db, order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="order not found")
    return order
```

In tests, override the dependency rather than mocking the import:

```python
app.dependency_overrides[get_db_session] = lambda: fake_session
```

## Request/Response Validation with Pydantic

Define explicit request and response models — don't accept/return raw dicts. FastAPI uses them to generate OpenAPI docs and to validate automatically, returning a `422` with field-level detail on failure without you writing that logic.

```python
from pydantic import BaseModel, Field

class PlaceOrderRequest(BaseModel):
    customer_id: str
    items: list[LineItem] = Field(min_length=1)

class OrderResponse(BaseModel):
    id: str
    status: str
    total_cents: int

@app.post("/orders", response_model=OrderResponse, status_code=201)
async def place_order(request: PlaceOrderRequest, service: OrderService = Depends(get_order_service)):
    order = service.place_order(request.customer_id, request.items)
    return order
```

`response_model` also strips any field on the returned object not declared in the model — a safety net against accidentally leaking an internal field.

## Async Route Handlers

Use `async def` for routes that await I/O (DB queries with an async driver, HTTP calls to another service). A plain `def` route handler is still supported and runs in a thread pool — fine for CPU-bound or sync-only-library code, but don't mix a blocking call inside an `async def` route (see the `python` skill's async section).

## Error Handling

Raise `HTTPException` for expected client-facing errors; let unexpected exceptions propagate to a global exception handler that logs full details server-side and returns a generic client-facing message:

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    logger.exception("Unhandled error on %s", request.url.path)
    return JSONResponse(status_code=500, content={"error": "internal server error"})
```

Never let an unhandled exception's traceback or message reach the client response body (see `application-security`'s security-misconfiguration guidance).

## Testing

Use `pytest-asyncio` and `httpx.AsyncClient` (or FastAPI's `TestClient`, which wraps it) to test routes through the real HTTP layer, with dependency overrides for anything external:

```python
import pytest
from httpx import AsyncClient, ASGITransport

@pytest.mark.asyncio
async def test_place_order_returns_201():
    app.dependency_overrides[get_order_service] = lambda: FakeOrderService()
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post("/orders", json={"customer_id": "c1", "items": [...]})
    assert response.status_code == 201
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Importing a DB session/client directly into a route handler | Use `Depends`, override it in tests |
| Accepting/returning raw dicts instead of Pydantic models | Define explicit request/response models |
| Letting an unhandled exception's traceback reach the client | Global exception handler, generic client-facing message |
| Mixing a blocking call inside an `async def` route | Use an async-native client, or make the route a plain `def` |
| Testing by calling the route function directly | Test through the real HTTP layer with `AsyncClient`/`TestClient` |

## Quick Reference

| Need | Pattern |
|---|---|
| Inject a DB session/client | `Depends(get_dependency)` |
| Validate a request body | Pydantic request model as a route parameter |
| Prevent leaking internal fields | `response_model` on the route |
| Global error handling | `@app.exception_handler(Exception)` |
| Test a route | `httpx.AsyncClient` / `TestClient`, dependency overrides for externals |
