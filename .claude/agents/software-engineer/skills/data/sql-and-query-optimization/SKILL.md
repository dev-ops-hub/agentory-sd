---
name: sql-and-query-optimization
description: Use when a query is slow, writing non-trivial SQL (window functions, CTEs), or interpreting an EXPLAIN plan
---

# SQL and Query Optimization

## Overview

Diagnosing and fixing slow queries, and writing advanced SQL correctly. For schema-level decisions (indexing strategy as part of table design, data types), see `database-design` — this skill is about an existing query's performance and correctness.

## When to Use

- A specific query is slow and needs diagnosis
- Writing window functions, recursive CTEs, or other advanced SQL
- Reviewing a query for an N+1 pattern or a missing index
- Interpreting an `EXPLAIN`/`EXPLAIN ANALYZE` plan

## Reading EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id = 42;
```

What to look for, in priority order:
1. **Seq Scan on a large table** where you expected an index to be used — means no usable index exists, or the planner decided the index wasn't selective enough (common when statistics are stale — try `ANALYZE table_name`).
2. **Actual rows vs. estimated rows diverging wildly** — a sign the planner's statistics are stale; `ANALYZE` the table.
3. **Nested Loop joining two large sets** — fine for small inputs, catastrophic as either side grows; a Hash Join or Merge Join is usually better for large joins, and the planner will choose correctly if an index/stats are in place.
4. **Total cost / actual time** at the outermost node tells you the overall query cost; drill into whichever child node has the largest share of it.

## Common Rewrite Patterns

```sql
-- ❌ Function on the indexed column prevents index use
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-15';

-- ✅ Range comparison can use an index on created_at
SELECT * FROM orders WHERE created_at >= '2024-01-15' AND created_at < '2024-01-16';
```

```sql
-- ❌ NOT IN with a subquery containing NULLs silently returns no rows
SELECT * FROM customers WHERE id NOT IN (SELECT customer_id FROM blocked);

-- ✅ NOT EXISTS handles NULLs correctly and is usually faster
SELECT * FROM customers c
WHERE NOT EXISTS (SELECT 1 FROM blocked b WHERE b.customer_id = c.id);
```

```sql
-- ❌ SELECT * fetches columns you don't need, including large/TOAST'd ones
SELECT * FROM orders WHERE id = 1;

-- ✅ Select only what's needed
SELECT id, status, total_cents FROM orders WHERE id = 1;
```

## The N+1 Query Pattern

The most common application-level performance bug: fetching a list, then issuing one additional query per item in a loop.

```python
# ❌ N+1: one query for orders, then one query per order for its customer
orders = db.query("SELECT * FROM orders LIMIT 50")
for order in orders:
    order.customer = db.query("SELECT * FROM customers WHERE id = %s", order.customer_id)
```

```python
# ✅ Batch: one query for orders, one query for all needed customers
orders = db.query("SELECT * FROM orders LIMIT 50")
customer_ids = {o.customer_id for o in orders}
customers = db.query("SELECT * FROM customers WHERE id = ANY(%s)", [list(customer_ids)])
customers_by_id = {c.id: c for c in customers}
for order in orders:
    order.customer = customers_by_id[order.customer_id]
```

ORMs make this easy to write accidentally via lazy-loaded relationships — check for an eager-load option (`select_related`/`prefetch_related` in Django, `joinedload`/`selectinload` in SQLAlchemy) before looping over a relationship.

## Window Functions

Use for "value relative to a group" without collapsing rows (unlike `GROUP BY`):

```sql
-- Running total per account, ordered by date
SELECT
    account_id,
    transaction_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY account_id
        ORDER BY transaction_date
    ) AS running_balance
FROM transactions;

-- Rank within each group
SELECT
    customer_id,
    order_total,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_total DESC) AS rank_within_customer
FROM orders;
```

## Recursive CTEs

For hierarchical/graph-shaped data (org charts, category trees, bill of materials):

```sql
WITH RECURSIVE org_chart AS (
    -- base case: top-level employees
    SELECT id, name, manager_id, 1 AS depth
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- recursive case: each employee's reports
    SELECT e.id, e.name, e.manager_id, oc.depth + 1
    FROM employees e
    JOIN org_chart oc ON e.manager_id = oc.id
)
SELECT * FROM org_chart ORDER BY depth;
```

Always include a depth/iteration guard in production use (`WHERE depth < 50`) in case of accidental cyclic data.

## Maintenance Commands

| Command | Purpose |
|---|---|
| `ANALYZE table_name` | Refresh planner statistics — run after large data changes |
| `EXPLAIN (ANALYZE, BUFFERS)` | Show actual execution + cache hit/miss info |
| `pg_stat_statements` | Postgres extension — surfaces the actual slowest/most-frequent queries in production, rather than guessing |
| `REINDEX` | Rebuild a bloated index (after heavy update/delete churn) |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Wrapping an indexed column in a function in `WHERE` | Rewrite as a range comparison the index can use |
| `NOT IN` with a subquery that can contain `NULL` | Use `NOT EXISTS` |
| `SELECT *` when only a few columns are needed | Select explicit columns |
| Looping over a result set issuing one query per row (N+1) | Batch into a single `WHERE id = ANY(...)` query, or use the ORM's eager-load option |
| Trusting the planner's row estimates after a big data change | Run `ANALYZE` |
| Recursive CTE with no depth guard | Add a depth/iteration limit to protect against cyclic data |

## Quick Reference

| Symptom | Likely cause | Check |
|---|---|---|
| Seq Scan where an index was expected | Missing/unusable index, or stale stats | `EXPLAIN ANALYZE`, then `ANALYZE table` |
| Query slow only in a loop | N+1 pattern | Batch the lookup |
| Function in WHERE clause, index unused | Function wraps the indexed column | Rewrite as a sargable range/equality comparison |
| Slow production queries, unclear which | Don't know yet | `pg_stat_statements` |
