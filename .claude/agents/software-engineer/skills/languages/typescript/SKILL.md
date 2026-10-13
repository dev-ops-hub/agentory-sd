---
name: typescript
description: Use when writing or reviewing TypeScript application/backend code — generics, strict-mode configuration, and type-design patterns for Node/backend services
---

# TypeScript

## Overview

Idiomatic TypeScript for backend/application code: strict typing, generics, and type-design patterns. For a specific backend framework (NestJS, Express), see that framework's own skill — this skill is language-level only.

## When to Use

- Writing or reviewing TypeScript backend/application code
- Deciding how to type a function with flexible input/output shapes (generics)
- Configuring a new project's `tsconfig.json`
- Reviewing a type definition for soundness

## Strict Mode, Always

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true
  }
}
```

`strict: true` is the floor, not a nice-to-have — it catches null/undefined misuse, implicit `any`, and unsafe property access at compile time instead of at runtime. `noUncheckedIndexedAccess` additionally forces you to handle the case where `arr[i]` or `obj[key]` is `undefined`, which plain `strict` mode doesn't catch.

## Generics

Use generics when a function's behavior is independent of the specific type it operates on — a repository, a cache wrapper, a result type:

```typescript
interface Repository<T, ID> {
  findById(id: ID): Promise<T | null>;
  save(entity: T): Promise<void>;
}

class PostgresRepository<T, ID> implements Repository<T, ID> {
  // one implementation serves every entity type that needs this shape
}
```

Avoid generics where a concrete type is clearer and nothing is actually reused — a generic with one call site is premature abstraction, not type safety.

## Discriminated Unions Over Optional Fields

Model mutually-exclusive states as a discriminated union, not a flat object with several optional fields — the compiler then forces every consumer to handle each case:

```typescript
// ❌ Any combination of fields is technically valid, including invalid ones
interface OrderResult {
  success?: boolean;
  order?: Order;
  error?: string;
}

// ✅ Only one shape per discriminant value is possible
type OrderResult =
  | { status: "success"; order: Order }
  | { status: "failed"; error: string };

function handle(result: OrderResult) {
  if (result.status === "success") {
    console.log(result.order); // narrowed, order is guaranteed present
  } else {
    console.log(result.error); // narrowed, error is guaranteed present
  }
}
```

## Conditional and Mapped Types

Use for deriving one type from another rather than hand-maintaining two definitions that must stay in sync:

```typescript
// Mapped type: derive a "partial update" shape from an entity type
type UpdateInput<T> = {
  [K in keyof T]?: T[K];
};

// Conditional type: extract the resolved type of a Promise
type Awaited2<T> = T extends Promise<infer U> ? U : T;
```

Don't reach for distributive conditional types or deep type-level computation unless a simpler type (a union, an interface) genuinely can't express the constraint — type-level complexity has a real readability cost for the next person touching the code.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `any` used to silence a type error | Use `unknown` and narrow it, or fix the actual type mismatch |
| Flat object with many optional fields representing mutually exclusive states | Discriminated union |
| `tsconfig.json` without `strict: true` | Enable it — retrofitting strict mode later is far more painful than starting with it |
| Generic type parameter used in exactly one place | Remove the generic; use the concrete type |
| Non-null assertion (`!`) to silence a possibly-undefined error | Narrow with an actual check, or fix why the value might be undefined |

## Quick Reference

| Need | Default |
|---|---|
| New `tsconfig.json` | `strict: true` + `noUncheckedIndexedAccess` |
| Mutually exclusive result shapes | Discriminated union, not optional fields |
| Reusable container/repository logic | Generics |
| Deriving a type from another | Mapped/conditional type, only when a plain union/interface can't express it |
| Silencing a type error with `any` | `unknown` + narrowing instead |
