---
sprint: 1
track: default
review_iteration: 2
generated_at: 2026-10-10
PR: "#9"
author: test-engineer
---
# Sprint 1 Test Report — PR #9 (Re-review)

## Verdict: PASS (no blockers)

All 23 automated pytest tests pass. Test coverage is appropriate for a Sprint 1 skeleton sprint.

## Test-Case Matrix

| TC ID | Status | Notes |
|---|---|---|
| TC-1.1 | PASS | pyproject.toml deps + uv.lock + db/ subpackage |
| TC-1.2 | PASS | GET /api/health -> 200 {"status":"ok"} |
| TC-1.3 | PASS | Only /api/health registered |
| TC-1.4 | PASS | All 6 tables created |
| TC-1.5 | PASS | Columns/types/constraints checked; CHECK constraint on trades.side verified |
| TC-1.6 | PASS | 1 profile + 10 watchlist rows |
| TC-1.7 | PASS | No reseed on restart |
| TC-1.8 | PASS | 0-byte file treated as missing |
| TC-1.9 | PASS | 8 concurrent threads produce exactly 1 seed |
| TC-1.10 | PASS | Missing parent directory created |
| TC-1.11 | PASS | Corrupted file raises error, not silently re-created |
| TC-1.12 | PASS | Unset/empty key selects simulator |
| TC-1.13 | PASS | Non-empty key selects Massive (tautology — see notes) |
| TC-1.14 | PASS | Whitespace-only key selects simulator |
| TC-1.15 | PASS | PriceQuote struct with 5 fields + frozen |
| TC-1.16 | PASS | PriceCache set/get round-trip |
| TC-1.17 | PASS | Arbitrary ticker accepted by provider stub |
| TC-1.21 | PASS | No GBM/Massive code in market_data/ |
| TC-1.18 | NOT TESTED | Docker integration — manual/CI only per spec |
| TC-1.19 | NOT TESTED | Frontend build — manual/CI only per spec |
| TC-1.20 | NOT TESTED | Frontend listing — manual/CI only per spec |
| TC-1.22 | NOT TESTED | Docker restart — manual/CI only per spec |
| TC-1.23 | NOT TESTED | uv.lock stale — manual/CI only per spec |

## Findings — Resolution Status

1. **TC-1.13 tautology** — LEFT AS-IS: Will become meaningful in Sprint 2/4 when real provider implementations replace the placeholder. Accepted per spec D4 (placeholder sprint).
2. **TC-1.5 missing CHECK constraint on trades.side** — **FIXED**: Test now verifies `CHECK (side IN ('buy', 'sell'))` is present in trades table's CREATE TABLE SQL.
3. **Environment variable pollution in factory tests** — **FIXED**: Tests use `unittest.mock.patch.dict(os.environ, {}, clear=True)` with `setup_method`/`teardown_method` for proper backup and restore.
