# <Product>: UX design

**Status:** draft | ready  **Sources:** <PRD path and sections, constitution version, agent-docs>  **Stack constraint:** <from the constitution, e.g. static export, styling layer>

## 0. Summary

Three to six lines: who it is for, the main screen in one sentence, what leads, and the one or two decisions most worth the owner's attention (by `UXD-n`).

## 1. Users and constraints

| Item | Content | Basis |
|---|---|---|
| Primary user | | `PRD §x` or `ASSUMPTION A<k>` |
| Main task and the decision they make | | |
| Device and width range | | |
| Hard rules that shape the UI | One line per constitution MUST that touches the interface, with principle number | constitution |

### Assumptions

| ID | Assumption | Why it matters | Basis |
|---|---|---|---|

## 2. Information architecture

```mermaid
flowchart TB
    %% sitemap: screens, panels, navigation, persistent elements
```

One paragraph: why this structure suits the main task.

## 3. Key flows

One diagram per flow that matters (the main task, the highest-risk action, first-run, failure). Name the screens and states it passes through.

```mermaid
flowchart LR
    %% flow: start, steps, decisions, end states
```

## 4. Screen inventory

| ID | Screen | Purpose | FRs covered | Priority | File |
|---|---|---|---|---|---|

Every in-scope FR that touches the UI appears in at least one row. List FRs with no UI under "Not designed" with the reason.

## 5. Design system summary

Layout grid, the colour roles in one line each, type scale in one line, spacing rhythm, the component set and which states each shares. Detail is in [design-tokens.md](design-tokens.md).

## 6. Accessibility

Keyboard order for the main screen, how colour-independence is met, target sizes, reduced motion, screen-reader notes for charts and live updates. Anything not yet measured is `UNVERIFIED` and listed in README.md.

## 7. Content and copy

Voice in three adjectives with a one-line example each; the error formula; the glossary of terms the UI uses and the terms it avoids; the standing labels the constitution requires, quoted exactly.

## 8. Responsive rules

What changes at each width: what collapses, what stacks, what is dropped and why.
