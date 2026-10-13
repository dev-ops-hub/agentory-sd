---
name: database-design
description: Use when designing a database schema, choosing data types or keys, planning a migration, or reviewing a schema for normalization and indexing issues
---

# Database Design

## Overview

Relational schema design: primary/foreign keys, data type choice, constraints, indexing, and migrations. For query-level performance tuning (EXPLAIN analysis, index strategy for a specific slow query), see `sql-and-query-optimization`.

## When to Use

- Designing a new table or set of related tables
- Choosing a primary key strategy or a column's data type
- Writing a migration (new column, rename, backfill)
- Reviewing an existing schema for normalization or missing-constraint issues

## Primary Keys

- A surrogate key (auto-increment integer or UUID) is usually simpler than a composite natural key — natural keys (email, SSN) can change, and using one as a foreign-key target propagates that fragility everywhere it's referenced.
- UUID vs. auto-increment integer: UUIDs avoid leaking row counts/creation order and work better for distributed ID generation (no central sequence); auto-increment integers are smaller, index better, and sort by insertion order for free. Pick based on whether IDs need to be generated outside a single DB instance.

## Foreign Keys and the Index Gotcha

**Postgres does not automatically index a foreign-key column.** Every foreign key should get an explicit index on the referencing column, or every join and every cascade delete on the parent will do a full table scan on the child.

```sql
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customers(id)
);
-- Without this, every query filtering/joining on customer_id scans orders fully:
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
```

## Data Type Choices

| Need | Use | Avoid |
|---|---|---|
| Money/currency | `NUMERIC(precision, scale)` or integer cents | `FLOAT`/`DOUBLE` (binary rounding errors), the Postgres `MONEY` type (locale-dependent formatting, imprecise arithmetic) |
| Variable-length text | `TEXT` | `VARCHAR(n)` for no real reason — Postgres `TEXT` has no performance penalty vs. `VARCHAR`; only use a length limit when the domain actually bounds it |
| Auto-increment ID | `BIGINT GENERATED ALWAYS AS IDENTITY` | `SERIAL` (older convention; identity columns are the modern standard and interact better with permissions) |
| Timestamps | `TIMESTAMPTZ` (timezone-aware) | `TIMESTAMP` without time zone — ambiguous across server/client timezone changes |

## Constraints

Push invariants into the schema wherever possible — a constraint enforced by the database holds even if application code has a bug:

```sql
CREATE TABLE positions (
    id BIGINT PRIMARY KEY,
    quantity NUMERIC(18,4) NOT NULL CHECK (quantity > 0),
    account_id BIGINT NOT NULL REFERENCES accounts(id)
);

-- EXCLUDE constraint: prevent overlapping date ranges for the same resource
CREATE EXTENSION IF NOT EXISTS btree_gist;
CREATE TABLE bookings (
    room_id BIGINT NOT NULL,
    during TSRANGE NOT NULL,
    EXCLUDE USING GIST (room_id WITH =, during WITH &&)
);
```

## Index Types

| Index type | Use for |
|---|---|
| B-tree (default) | Equality and range queries on sortable types — the default choice |
| GIN | Full-text search, JSONB containment queries, array membership |
| GiST | Geometric data, range types, exclusion constraints |
| Partial index | A query that always filters on a condition (`WHERE status = 'active'`) — index only matching rows, smaller and faster than indexing everything |
| Composite index | A query that always filters/sorts by multiple columns together — column order in the index should match the most common query's filter order |

## Normalization — and When to Diverge

Normalize (3NF: no transitive dependencies, no repeating groups) by default — it prevents update anomalies (the same fact stored in two places getting out of sync). Deliberately denormalize only when:
- A specific, measured read pattern needs a pre-joined/aggregated shape and the write-side synchronization cost is accepted (this is what CQRS formalizes — see `distributed-systems-patterns`)
- The denormalized copy has a clear, enforced update path (trigger, application-level write-through) so it can't silently drift

## Migrations

- **Additive-first for zero downtime:** add a new column (nullable or with a default), backfill in batches, then add `NOT NULL`/constraints once backfilled — don't add a `NOT NULL` column with no default to a large table in one step, it locks/rewrites the whole table in some databases.
- **Renaming a column with zero downtime:** add the new column, write to both old and new (dual-write) during a transition window, backfill, switch reads to the new column, then drop the old one — a straight `ALTER COLUMN RENAME` breaks any code still deployed against the old name during a rolling deploy.
- **Always write a rollback path** for a migration, and test it — a migration that can't be reversed turns any discovered problem into a forward-only scramble.

## Common Mistakes

| Mistake | Fix |
|---|---|
| No index on a foreign-key column | Add one explicitly — Postgres doesn't do this automatically |
| Storing money as `FLOAT` | Use `NUMERIC` or integer cents |
| `TIMESTAMP` without time zone | Use `TIMESTAMPTZ` |
| Adding `NOT NULL` with no default to a large existing table | Add nullable/defaulted, backfill in batches, then constrain |
| Renaming a column in one step during a rolling deploy | Add-copy-backfill-switch-drop, not a direct rename |
| Denormalizing without an enforced update path | Only denormalize with a trigger or write-through keeping the copy in sync |

## Quick Reference

| Decision | Default |
|---|---|
| Money column | `NUMERIC` or integer cents, never `FLOAT` |
| New foreign key | Always pair with an explicit index |
| Timestamp column | `TIMESTAMPTZ` |
| Large-table column rename | Add-copy-backfill-switch-drop |
| New required column on existing large table | Nullable/defaulted first, then backfill, then constrain |
