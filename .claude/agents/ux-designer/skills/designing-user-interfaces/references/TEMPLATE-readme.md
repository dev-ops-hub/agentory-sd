# UX design: <product> (index for the project owner)

**Status:** draft | ready for vetting  **Track:** <default | name>  **Updated:** <date>  **Sources:** <PRD path and sections, constitution version, agent-docs files>

## Reading order

| # | File | Read it to decide |
|---|---|---|
| 1 | [ux-design.md](ux-design.md) | Is the structure and the flow right? |
| 2 | [screens/](screens/) | Is each screen right? Each ends in its Rationale |
| 3 | [decisions.md](decisions.md) | Accept or reject each `UXD-n` |
| 4 | [design-tokens.md](design-tokens.md) | Is the look right? |

## Vetting checklist

- [ ] Every `Proposed` decision in decisions.md is set to `Accepted` or `Rejected`
- [ ] Each screen's wireframe and Rationale read correctly
- [ ] Every open question below is answered

## Screens

| ID | Screen | FRs | Decisions | Status |
|---|---|---|---|---|
| S01 | | | | draft |

## Open questions

- **Q1** [PM] <question> - impact: <what changes> - assumed meanwhile: A<k>
- **Q2** [USER] <question> - impact: ... - assumed meanwhile: A<k>

Write `None` only when every assumption is confirmed.

## Verification still to run

Checks the designer cannot run. Each names what it covers and what passing means.

| Check | Covers | Passing means |
|---|---|---|
| Contrast of every text and UI colour pair, both themes | design-tokens.md pairs marked `UNVERIFIED` | AA: 4.5:1 body, 3:1 large text and UI |
| Automated accessibility scan of the built screens | All screens | No violations |
| Overflow at the narrowest supported width | All screens | No horizontal scroll |
| Visual check of each screen in a browser | All screens | Matches the wireframe and Rationale |
