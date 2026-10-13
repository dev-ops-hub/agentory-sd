---
name: e2e-browser-testing
description: Use when writing or reviewing browser end-to-end tests, choosing selectors, structuring a Page Object Model, or diagnosing a flaky UI test
---

# E2E Browser Testing

## Overview

Patterns for end-to-end tests that drive a real browser against the application. For *whether* a user journey needs an E2E test at all (vs. a lower, faster test level), see `testing-principles`. This skill is about writing E2E tests well once you've decided one belongs: selector strategy, structure, and flaky-test diagnosis.

Default framework: **Playwright**, matching this project's stack (`frontend/playwright.config.*`). If a project already standardizes on Cypress, Selenium, or Puppeteer, follow that convention instead of introducing a second framework — check for an existing config file before assuming.

## When to Use

- Writing a new E2E test for a critical cross-component user journey (login, checkout, confirm/reject flow, trade submission)
- Reviewing an existing E2E suite for brittle selectors or unnecessary waits
- A UI test fails intermittently and the cause isn't obvious from the failure message alone

## Selector Priority

Prefer selectors tied to what a user or assistive technology would perceive, not to markup structure that can change for purely visual reasons:

1. **Role** — `getByRole('button', { name: 'Confirm trade' })`
2. **Label** — `getByLabel('Quantity')`
3. **Accessible name / text** — `getByText('Simulated prices')`
4. **Test ID** — `getByTestId('trade-confirm-button')`, as a last resort when no accessible selector exists

Avoid CSS selectors tied to class names or DOM nesting (`.card > div:nth-child(2) > button`) — a presentation-only refactor breaks the test with no change in actual behavior.

```typescript
// ❌ Brittle — breaks on any markup/class change
await page.locator('.watchlist-row:nth-child(3) .btn-sm').click();

// ✅ Resilient — tied to what the user actually sees/hears
await page.getByRole('row', { name: /AAPL/ }).getByRole('button', { name: 'Remove' }).click();
```

## Web-First Assertions

Use Playwright's auto-retrying assertions instead of manual waits — they poll until the condition holds or the timeout elapses, which is what makes a test both fast on the happy path and tolerant of real async rendering:

```typescript
// ❌ Arbitrary sleep — slow when unnecessary, flaky when insufficient
await page.click('button');
await page.waitForTimeout(1000);
expect(await page.locator('.status').textContent()).toBe('Confirmed');

// ✅ Auto-retrying assertion — waits exactly as long as needed
await page.getByRole('button', { name: 'Confirm' }).click();
await expect(page.getByText('Confirmed')).toBeVisible();
```

Never add a fixed `waitForTimeout` to make a flaky test pass — it hides the real race condition and reintroduces flakiness under different load/timing (see `systematic-debugging`'s `condition-based-waiting.md` for the general technique this specializes).

## Page Object Model (POM)

For a suite beyond a handful of tests, wrap each screen's interactions in a page object so selector changes are fixed in one place:

```typescript
class WatchlistPage {
  constructor(private page: Page) {}

  async addTicker(symbol: string) {
    await this.page.getByLabel('Ticker symbol').fill(symbol);
    await this.page.getByRole('button', { name: 'Add' }).click();
  }

  rowFor(symbol: string) {
    return this.page.getByRole('row', { name: new RegExp(symbol) });
  }
}
```

Keep assertions in the test, not the page object — the page object exposes locators and actions; the test decides what "correct" means for that scenario.

## Testing User-Visible Outcomes, Not Implementation

Assert on what the user would see (text, visibility, enabled/disabled state), not on internal state (a Redux store value, a CSS class used only for styling). An implementation refactor that doesn't change behavior shouldn't break the test.

## Diagnosing Flaky E2E Tests

A test that passes sometimes and fails other times, with no code change between runs, is **flaky** — never fix it by adding a retry or a longer timeout without first investigating:

| Suspect | Check |
|---|---|
| Race condition | Does the test assert immediately after an action that triggers an async update (API call, animation)? Switch to a web-first assertion that waits for the end state. |
| Shared state | Does this test depend on data left by another test (same ticker, same browser storage)? Isolate: fresh context/storage per test. |
| Test order dependency | Does it pass in isolation but fail in the full suite? Look for global state (a shared fixture, a seeded DB row) one test mutates and another assumes unchanged. |
| Network dependency | Is a real third-party call involved? Mock the network boundary for E2E unless the test's specific purpose is verifying that integration. |
| Selector instability | Does the element briefly exist twice during a transition (old + new render)? Scope the locator more precisely or wait for the transition to finish. |

Report both the passing and failing runs' evidence rather than rerunning until green — see `defect-triage`'s flaky-test handling for how to classify and report it.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Selecting by CSS class/structure | Use role/label/text/test-id, in that priority order |
| `waitForTimeout` to fix a flaky test | Switch to a web-first assertion or condition-based wait |
| Asserting on internal state instead of what renders | Assert on visible text, role, or accessible state |
| One test depends on another's leftover state | Isolate: fresh browser context/storage per test |
| Rerunning a flaky test until it's green and reporting pass | Classify as FLAKY and investigate; report both outcomes |

## Quick Reference

| Need | Approach |
|---|---|
| Selector | role → label → accessible text → test id |
| Waiting for an async update | Web-first auto-retrying assertion, never a fixed sleep |
| Repeated interaction across tests | Page Object Model, assertions stay in the test |
| Suite growing beyond a handful of E2E tests | Reassess with `testing-principles` — can some move to a lower test level? |
| Intermittent failure | Diagnose per the flaky-test table above before touching timeouts |
