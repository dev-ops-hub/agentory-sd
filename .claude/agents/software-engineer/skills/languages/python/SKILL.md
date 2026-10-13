---
name: python
description: Use when writing or reviewing Python application code — idiomatic patterns, type hints, async/await, dependency and tooling conventions (uv/ruff)
---

# Python

## Overview

Idiomatic Python for application/backend code: typing, async, modern tooling conventions. Framework-specific guidance (FastAPI, Django) lives in its own skill under `frameworks/` — load this skill for language-level concerns, that one for framework-level concerns.

## When to Use

- Writing or reviewing Python application code
- Deciding whether something should be sync or async
- Setting up type hints on a function or class
- Choosing dependency/tooling conventions for a Python project

## Type Hints

Type hints are not optional documentation — treat them as load-bearing and check them with a type checker in CI (`mypy` or `pyright`).

```python
from typing import Protocol

def calculate_total(items: list[LineItem], discount_pct: float = 0.0) -> Decimal:
    ...

class Repository(Protocol):
    def find_by_id(self, id: str) -> Order | None: ...
```

Use `Protocol` for structural typing of dependencies (see `software-architecture`'s ports/adapters pattern) rather than requiring a concrete base class — it lets a test fake satisfy the type without inheriting from anything real.

## Async / Await

- Use `async def` for I/O-bound work (DB queries, HTTP calls) where the framework/driver supports it end-to-end — mixing a blocking call inside an async function blocks the entire event loop, not just that request.
- Never call a blocking library (e.g., `requests`, a sync DB driver) from inside `async def` without offloading it (`asyncio.to_thread` or an async-native equivalent) — it silently serializes everything else on that event loop.
- `asyncio.gather` for concurrent independent awaitables; sequential `await` only when one result depends on the previous.

```python
# ❌ Blocks the entire event loop for every other coroutine
async def get_user(user_id: str):
    return requests.get(f"/users/{user_id}").json()

# ✅ Async-native client, or offload the blocking call
async def get_user(user_id: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(f"/users/{user_id}")
        return response.json()
```

## Dependency and Tooling Conventions

| Need | Tool |
|---|---|
| Dependency management + virtualenv | `uv` (fast, lockfile-based) — this repo's stack uses `uv` per the project constitution |
| Linting + formatting | `ruff` (replaces flake8/black/isort in one tool) |
| Type checking | `mypy` or `pyright` in CI |
| Testing | `pytest`, with `pytest-asyncio` for async test functions |

```bash
uv add fastapi          # add a dependency
uv run pytest            # run tests in the project's locked environment
ruff check . && ruff format .
```

## Patterns Worth Knowing

- **Dataclasses/Pydantic models over raw dicts** for structured data crossing a boundary — gives you validation and type safety instead of a `KeyError` discovered at runtime.
- **Context managers (`with`)** for anything with a cleanup step (file handles, DB transactions, locks) — don't rely on manual `.close()` calls that skip on an exception path.
- **f-strings for formatting, never for building SQL/shell commands** — see `secure-engineering`; an f-string is exactly the pattern that causes injection when the value is untrusted.

```python
from dataclasses import dataclass
from pydantic import BaseModel

@dataclass(frozen=True)
class Money:
    cents: int
    currency: str = "USD"

class OrderRequest(BaseModel):  # Pydantic: validates on construction
    customer_id: str
    items: list[LineItem]
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Calling a blocking library inside `async def` | Use an async-native client, or `asyncio.to_thread` |
| Mutable default argument (`def f(items=[])`) | Default to `None`, create the list inside the function body |
| Catching bare `Exception` broadly | Catch specific exception types |
| Passing raw dicts across module/service boundaries | Use a dataclass or Pydantic model |
| Using `pip` + `requirements.txt` with no lockfile | Use `uv` with a lockfile for reproducible installs |

## Quick Reference

| Need | Default |
|---|---|
| Dependency management | `uv` |
| Lint/format | `ruff` |
| Type checking | `mypy`/`pyright` in CI |
| Structured data at a boundary | `dataclass` or Pydantic model, not a raw dict |
| I/O-bound function | `async def` with an async-native client |
