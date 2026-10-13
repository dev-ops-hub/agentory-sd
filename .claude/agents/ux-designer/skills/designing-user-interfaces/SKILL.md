---
name: designing-user-interfaces
description: Use when designing, revising or reviewing the user interface of a product from a PRD, when screens, flows, components or a design system must be specified before any code is written, or when the project owner needs to vet design decisions and their rationale
---

# Designing User Interfaces

## Overview

The output of a UI design task is a set of files in `planning/ux/` that a project owner can read, challenge and approve without running anything. Every screen carries its rationale, and every non-obvious choice is a numbered decision with a source.

Core principle: **a reader can trace each layout, component and word to a user need, a PRD requirement, a constitution rule or a numbered assumption.**

## Workflow

1. Read the constraints first: constitution, PRD, `agent-docs/`, and whatever `planning/ux/` already holds. Note which constitution MUST rules touch the UI (price labelling, confirmation steps, disabled states, what may be shown). Each becomes an acceptance point on the screens it touches.
2. Read `design-doctrine`, then the skill for the work in hand (`data-dashboard` for number-heavy screens, `design-component`, `design-tokens`, `ux-writing`). Use the path map in the agent definition for `rules/` and `reference/`. Then resolve whether a component library skill is installed (project or global) per the "Component library" section of the agent definition: if it is, read it and specify in its vocabulary before naming any component or colour; if it is not, design generically and raise the `[USER]` Gap that section describes.
3. Work top-down: users and constraints, information architecture, flows, screen inventory, then each screen, then tokens. Decide the system (tokens, layout grid, component set) once; screens use it.
4. Write each file from its template in `references/`. Create `planning/ux/` files in this order: `decisions.md`, `design-tokens.md`, `screens/`, `ux-design.md`, `README.md`.
5. Reconcile before returning: every screen cites decisions that exist; every decision is cited by a screen or the system; every FR in scope appears in at least one screen's trace; every `[PM]`/`[USER]` question is in `README.md`.

## Deliverables

| File | Holds | Template |
|---|---|---|
| `planning/ux/README.md` | Index, status of each file, reading order for the owner, the vetting checklist, open Gaps, Verification still to run | `TEMPLATE-readme.md` |
| `planning/ux/ux-design.md` | Users and constraints, information architecture, key flows, screen inventory with FR trace, design-system summary, accessibility, content approach, responsive rules | `TEMPLATE-ux-design.md` |
| `planning/ux/screens/S<NN>-<slug>.md` | One screen: purpose, wireframe, components and states, data, interactions, copy, edge states, responsive, accessibility, **Rationale** | `TEMPLATE-screen.md` |
| `planning/ux/decisions.md` | The decision log: `UXD-<n>`, Status `Proposed`, context, options, decision, rationale, consequences, trace | `TEMPLATE-decisions.md` |
| `planning/ux/design-tokens.md` | Colour, type, spacing, radius, motion and chart tokens by tier, with role and basis, mapped to the stack's styling layer | `TEMPLATE-tokens.md` |

For a named track, use `planning/ux/<track>/` with the same files.

## Rationale rules

- Each screen's **Rationale** section answers: who uses it and what they decide there, what leads and why, why the regions sit where they do, what was left out and why, and which constitution rules shaped it. Two to six sentences per point, each ending in decision IDs or FR numbers.
- A choice goes into `decisions.md` when it is costly to reverse, when a reasonable designer would have chosen differently, or when it trades one user need for another. Routine choices that follow a doctrine rule cite the rule instead (`design-doctrine: one thing leads`).
- Every decision lists at least two options. A decision with one option is a constraint; say which source imposes it.
- Status starts `Proposed`. Only the project owner sets `Accepted` or `Rejected`.

## Wireframes and diagrams

Draw wireframes as fenced text blocks with labelled regions and approximate proportions. Draw flows and the sitemap as ```` ```mermaid ```` blocks. Name every region and show it at the desktop width and the narrowest supported width. Do not produce images or HTML unless the caller asks for a prototype.

## Checks you cannot run

You have no shell or browser, so contrast ratios, axe results, responsive overflow and render checks are not verified. Colour pairs get a stated target (for example AA 4.5:1 for body text, 3:1 for large text and UI) and the tag `UNVERIFIED`. List each check, the pairs or screens it covers and the upstream gate that does it under **Verification still to run**, for the caller to run.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Rationale that restates the layout ("the chart is on the left because it is on the left") | Name the need or rule served and the alternative rejected |
| Decisions buried in screen prose | Promote to `decisions.md` and cite the ID |
| A measured-sounding claim ("passes WCAG AA") | Tag `UNVERIFIED` and list the check to run |
| Four equal cards, no lead | Pick the one thing that leads; see `design-doctrine` |
| Only the happy path | Specify loading, empty, error, stale and disabled states per region |
| A constitution rule met only in prose | Make it a visible element with a test point on the screen |
| Inventing user research | Use the PRD personas; mark anything else `ASSUMPTION` |
| Asking the user what the PRD answers | Tag `[PM]`; only taste, assets and devices are `[USER]` |
