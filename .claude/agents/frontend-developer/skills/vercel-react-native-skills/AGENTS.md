# React Native Skills (Compact)

Version: 1.1.0-compact
Audience: coding agents working on React Native and Expo apps.
Goal: avoid runtime crashes and keep interactions at native-feel performance.

## Fast Path

Apply in this order:
1. Prevent known RN crash patterns.
2. Fix list virtualization and prop stability.
3. Keep animation work off the JS bottleneck.
4. Simplify state and render paths.

## Activation

Use this guidance when changing:
- RN components, screens, or navigation flows.
- FlatList/FlashList/LegendList rendering.
- Gestures, animations, and scroll performance.

## Critical Rules

### 1) Crash Prevention
- Never render raw strings outside `<Text>`.
- Avoid `{value && <View/>}` when `value` can be `0` or empty string.
- Prefer explicit boolean checks or ternaries with `null`.

### 2) List Performance
- Use a virtualized list for any medium/large dataset.
- Keep `renderItem` props stable; avoid inline object literals.
- Pass primitives when possible into memoized rows.
- Supply stable keys and item type hints for heterogeneous lists.
- Keep rows lightweight; defer heavy media/format work.

### 3) Animation and Gestures
- Prefer transform and opacity animations.
- Keep per-frame work on UI-friendly animation primitives.
- Avoid driving high-frequency animation from React state updates.
- Use native-feel gesture primitives for press/drag interactions.

### 4) Scroll and Input Responsiveness
- Do not track scroll position in React state every frame.
- Throttle/debounce expensive derived work from scrolling.
- Keep expensive formatting/calc outside render hot loops.

### 5) State Architecture
- State should represent ground truth, not duplicated derivations.
- Derive display values during render when cheap.
- Use functional updates when next state depends on previous state.
- Split independent concerns to reduce wide rerenders.

### 6) Navigation and Screen Composition
- Prefer native-backed navigators.
- Keep screen-level data fetching and expensive setup out of deeply nested children.
- Preserve clear boundaries between shell layout and dynamic content.

## Expo and Assets

- Use optimized image components and pre-sized assets.
- Load fonts/assets in a startup strategy that avoids layout jank.
- Avoid over-fetching large images for list thumbnails.

## Review Checklist

Before finalizing, verify:
- No risky `&&` leaked render cases.
- No text nodes outside `<Text>`.
- No inline prop churn in list items.
- No JS-thread-heavy animation loops.
- No unnecessary wide state causing full-screen rerenders.

## Anti-Patterns To Reject

- Inline object creation in every `renderItem` call.
- Animating layout properties for high-frequency interactions.
- Using React state as a frame-by-frame motion store.
- Huge screen components mixing navigation, data, and rendering logic.

## Output Contract For Agents

For each refactor, report:
1. Which performance or stability issue was fixed.
2. Which critical rule was applied.
3. Why UI behavior remains equivalent.
4. How to validate with one runtime scenario and existing tests.
