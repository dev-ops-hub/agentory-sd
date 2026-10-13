# React View Transitions (Compact)

Version: 1.1.0-compact
Audience: agents implementing transitions in React/Next.js.
Goal: add meaningful motion without regressions, excess code, or token-heavy guidance.

## Fast Path

Implement in order when applicable:
1. Shared element continuity.
2. Suspense reveal transitions.
3. List identity transitions.
4. Enter/exit transitions for conditional UI.
5. Page-level route transitions.

## Activation

Use this skill when adding or refactoring:
- Route/page transitions.
- Shared element animations.
- Suspense reveal choreography.
- Direction-aware forward/back motion.

## Core Rules

### 1) Animate Meaning, Not Decoration
- Every transition must communicate relationship, continuity, or hierarchy.
- If no clear semantic value, disable transition for that change.

### 2) Correct Triggering
- Use React transition-aware updates for transitionable state changes.
- Normal immediate updates without transition context should not be forced.

### 3) Shared Element Integrity
- Use stable unique names per logical entity.
- Ensure old and new elements participate in the same transition window.
- Avoid duplicate mounted elements sharing one transition name.

### 4) Directionality
- Use directional motion only for hierarchical or ordered navigation.
- Use neutral fades for lateral/tab-like navigation.
- Do not imply spatial depth where none exists.

### 5) Safe Fallbacks
- Unsupported browsers must degrade gracefully to no-animation behavior.
- Keep `default` mappings explicit to avoid accidental animation gaps.

### 6) Performance
- Keep transition CSS lightweight and composited where possible.
- Avoid expensive layout-triggering effects during transitions.
- Prevent transition logic from blocking navigation or data loading.

## Practical Pattern Map

- List -> detail: shared element + directional page transition.
- Detail -> list: reverse directional transition.
- Async data reveal: local enter transition on resolved content.
- Revalidation refresh: usually no motion or very subtle fade.

## Review Checklist

Before finalizing, verify:
- Transition conveys a user-understandable relationship.
- Forward/back types are applied only to ordered/hierarchical flows.
- Shared names are unique and stable.
- No hard dependency on browser support.
- No jank introduced during fast navigation.

## Anti-Patterns To Reject

- Global transitions on every state update.
- Directional slides for unrelated tab switches.
- Shared names reused by multiple concurrently mounted elements.
- Transition config that silently resolves to no-op due to missing defaults.

## Output Contract For Agents

When delivering changes, include:
1. Which transition pattern(s) were implemented.
2. Why each pattern matches the navigation semantics.
3. Fallback behavior on unsupported environments.
4. One manual test flow proving continuity and no jank.
