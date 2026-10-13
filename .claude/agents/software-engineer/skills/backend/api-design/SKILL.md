---
name: api-design
description: Use when designing a new API endpoint or contract, choosing between REST/GraphQL/RPC, versioning an existing API, or reviewing an API shape before implementation
---

# API Design

## Overview

Designing the contract an API presents to its callers: resource modeling, HTTP semantics, GraphQL schema design, and versioning — independent of any specific framework.

## When to Use

- Designing a new endpoint, resource, or GraphQL schema before implementing it
- Choosing between REST, GraphQL, and RPC/gRPC for a given use case
- An existing API needs a breaking change and needs a versioning strategy
- Reviewing whether an API shape will hold up (idempotency, pagination, error shape)

## REST Resource Modeling

Model around nouns (resources), not verbs — the HTTP method carries the verb:

| Resource action | Method + path |
|---|---|
| List orders | `GET /orders` |
| Get one order | `GET /orders/{id}` |
| Create an order | `POST /orders` |
| Replace an order | `PUT /orders/{id}` |
| Partially update | `PATCH /orders/{id}` |
| Cancel an order | `POST /orders/{id}/cancel` (action that isn't a plain CRUD verb) |

Rules of thumb:
- Plural nouns for collections (`/orders`, not `/order`)
- Nest only one level deep normally (`/orders/{id}/items`, not `/customers/{id}/orders/{id}/items/{id}`) — pass the parent ID as a query param if deeper nesting is tempting
- `GET` and `DELETE` are idempotent and safe/side-effect-free (GET) by contract — never put a mutation behind a GET
- Status codes mean something specific: `200` success, `201` created (with `Location` header), `204` no content, `400` client error (malformed request), `401` unauthenticated, `403` unauthorized, `404` not found, `409` conflict, `422` semantically invalid, `429` rate limited, `500` server error. Don't return `200` with an `{"error": ...}` body — use the status code.

## Versioning Strategies

| Strategy | Example | Tradeoff |
|---|---|---|
| **URI versioning** | `/v2/orders` | Most visible/discoverable; clients must change the URL to upgrade |
| **Header versioning** | `Accept: application/vnd.api+json;version=2` | Clean URLs, but less discoverable; easy to forget to set |
| **Field-level evolution** | Add new optional fields, never remove/repurpose existing ones; deprecate with a sunset date | No version bump needed for additive changes; requires discipline about never making a breaking change without bumping |

Pick one strategy per API and apply it consistently. For an internal API with a small number of known callers, field-level evolution (strictly additive changes) often avoids versioning entirely — reserve URI/header versioning for genuinely breaking changes.

## GraphQL Schema Design

Schema-first: define the type graph before resolvers. Key decisions:
- **Nullability is a contract.** A non-null field (`String!`) that can actually fail breaks every client depending on it being present — default to nullable unless truly guaranteed.
- **Avoid N+1 queries** from naive per-field resolvers calling the DB individually for each item in a list — batch with a DataLoader-style pattern (collect requested IDs across the batch, issue one query).
- **Field-level authorization**, not just query-level — a field returning sensitive data needs its own check, since GraphQL lets clients request any combination of fields.
- **Mutations return the changed object**, not just a success flag, so the client doesn't need a follow-up query.

```graphql
type Mutation {
  placeOrder(input: PlaceOrderInput!): PlaceOrderPayload!
}

type PlaceOrderPayload {
  order: Order
  errors: [UserError!]!   # structured errors, not just a top-level GraphQL error
}
```

## Idempotency and Pagination

- **Idempotency keys** for any `POST` that creates something with real-world side effects (a charge, an order): accept a client-supplied idempotency key; a retried request with the same key returns the original result rather than creating a duplicate.
- **Cursor-based pagination** over offset-based for anything that can grow or mutate between pages — offset pagination skips/duplicates rows when the underlying data changes between page requests.

```
GET /orders?cursor=eyJpZCI6MTIzfQ&limit=50
→ { "items": [...], "next_cursor": "eyJpZCI6MTczfQ" }
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Verbs in REST paths (`/getOrders`, `/createOrder`) | Use nouns + HTTP method; reserve verb-like paths for genuine non-CRUD actions |
| Returning `200` with an error payload | Use the status code that matches the actual outcome |
| Removing or repurposing a field without a version bump | Only add fields in-place; breaking changes get a new version |
| Offset pagination on a frequently-changing collection | Use cursor-based pagination |
| No idempotency key on a side-effecting `POST` | Add one; a client retry must not double-create |
| GraphQL resolver issuing one query per list item | Batch with a DataLoader-style pattern |

## Quick Reference

| Decision | Default |
|---|---|
| New resource endpoint shape | Noun-based path + correct HTTP method/status |
| Breaking change needed | Version the API (URI or header, pick one and stay consistent) |
| Side-effecting POST | Require/accept an idempotency key |
| Large or mutating collection | Cursor-based pagination |
| GraphQL field returning sensitive data | Field-level auth check, not just query-level |
