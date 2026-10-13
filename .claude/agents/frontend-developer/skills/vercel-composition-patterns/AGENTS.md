# React Composition Patterns (Compact)

Version: 1.1.0-compact
Audience: agents refactoring reusable React component APIs.
Goal: reduce complexity from boolean-driven APIs and improve maintainability.

## Fast Path

Use this sequence for component refactors:
1. Identify boolean-prop proliferation.
2. Define explicit variants or compound subcomponents.
3. Lift state to the narrowest shared owner.
4. Keep consumer-facing API small and intention-revealing.

## Activation

Use when working on:
- Shared UI primitives and design-system components.
- Components with many optional booleans.
- Reusable workflows with many behavior modes.

## Core Rules

### 1) Avoid Boolean Explosion
- Do not encode major mode differences as stacked booleans.
- Prefer explicit variants, wrappers, or separate composed assemblies.

### 2) Prefer Composition Over Flags
- Expose composable slots/subcomponents instead of large prop matrices.
- Keep each subcomponent focused on one responsibility.

### 3) Use Compound Components Thoughtfully
- Share state via context only where needed.
- Keep context values stable to avoid broad rerenders.
- Export a small, coherent surface area.

### 4) Separate State Logic From Presentation
- Put orchestration logic in hooks/providers.
- Keep render components mostly declarative and deterministic.

### 5) Keep APIs Predictable
- Favor explicit required props over "smart" inference.
- Prefer stable naming and behavior across variants.
- Minimize magic coupling between distant props.

## Refactor Heuristics

Choose split when:
- One component serves unrelated journeys.
- Condition branches dominate render body.
- Tests require combinatorial prop matrices.

Choose composition when:
- Variants share a stable frame and differ in internals.
- Consumers need controlled extension points.

## Review Checklist

Before finalizing, verify:
- Fewer booleans and fewer invalid prop combinations.
- Clearer ownership of state and side effects.
- Equivalent behavior for existing supported variants.
- Simpler tests focused on variant intent.

## Anti-Patterns To Reject

- "One component to rule them all" with many mode flags.
- Context carrying unrelated state for convenience.
- Hidden coupling where one prop silently rewires another.

## Output Contract For Agents

For each API refactor, provide:
1. Previous complexity hotspot.
2. Composition strategy selected.
3. Compatibility notes or migration path.
4. Validation via tests and one example usage per variant.
