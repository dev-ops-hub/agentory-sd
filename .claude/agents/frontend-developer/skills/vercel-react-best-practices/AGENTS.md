# React Best Practices (Compact)

Version: 1.1.0-compact
Audience: coding agents working on React and Next.js.
Goal: ship faster pages with fewer regressions and lower token cost.

## Fast Path

Apply these in order before writing code:
1. Remove request waterfalls.
2. Keep client bundles small.
3. Minimize rerenders from unstable references.
4. Use platform primitives (Suspense, transitions, server components) before custom state machinery.

## Activation

Use this guidance when changing:
- React components, hooks, or client/server boundaries.
- Next.js routes, server actions, and data fetching.
- Rendering performance, bundle size, or interaction latency.

## Critical Rules

### 1) Eliminate Waterfalls
- Start independent async work together via `Promise.all`.
- Delay `await` until a value is actually needed.
- Check cheap sync guards before expensive async calls.
- In Next.js, fetch near usage but ensure independent branches run in parallel.

### 2) Keep Bundles Small
- Avoid broad barrel imports in hot client paths.
- Lazy-load heavy UI and third-party libraries.
- Prefer static import paths so bundlers split correctly.
- Move non-interactive logic to server components when possible.

### 3) Respect Server/Client Boundaries
- Do not pass large serialized objects across RSC boundaries.
- Avoid duplicate serialization of the same payload.
- Do not store request-specific mutable data in shared module state.
- Authenticate server actions like any external API surface.

### 4) Minimize Rerenders
- Derive values during render; avoid redundant state.
- Avoid inline object/function props in frequently rerendered trees.
- Extract stable subtrees into memoized leaf components when profiling shows churn.
- Use functional state updates when next state depends on prior state.

### 5) Use Effects Sparingly
- Effects sync with external systems only.
- Move interaction logic into handlers, not effects.
- Keep dependency arrays exact and minimal.
- Prefer refs for transient mutable values that should not rerender.

### 6) Rendering and UX Performance
- Use Suspense boundaries intentionally for progressive reveal.
- Prefer transform/opacity animations over layout-thrashing properties.
- Defer non-critical scripts and post-interaction work.
- Use transitions for non-urgent updates that should not block typing/clicking.

## Next.js-Specific Guidance

- Server-first by default; add `"use client"` only where required.
- Keep route segments independently streamable.
- Use caching/revalidation deliberately; avoid accidental stale or uncached hot paths.
- Use `after()` for non-user-blocking post-response work where supported.

## Review Checklist

Before finalizing a change, verify:
- No avoidable sequential awaits in the critical path.
- No unnecessary client imports of heavy dependencies.
- No unstable prop identities causing list/tree churn.
- No effect doing pure computation that belongs in render.
- No server/client boundary passing oversized objects.

## Anti-Patterns To Reject

- "Fetch A then B" when A and B are independent.
- Large client utility imports for one tiny helper.
- State for values that can be derived from props/state.
- Global mutable module cache holding request/user-scoped data.
- Effects used as event handlers.

## Output Contract For Agents

When proposing changes, include:
1. What latency or bundle issue was identified.
2. Which critical rule was applied.
3. Why behavior is preserved.
4. How to verify (build/lint/test and one runtime check).

Prefer small, composable diffs over broad rewrites.
