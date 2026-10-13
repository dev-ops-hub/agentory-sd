---
artifact: user-story
version: "1.0"
created: <YYYY-MM-DD>
status: draft
---

# User Story: [Story Title]

## Story Header

| Field | Value |
|-------|-------|
| ID | [US-XXX] |
| Title | [Brief descriptive title] |
| Persona | [User persona] |
| Priority | [P0/P1/P2] |
| Epic/Feature | [Parent feature or epic] |
| Estimate | [Story points or T-shirt size] |

## User Story Statement

**As a** [specific user persona],

**I want** [action or capability],

**so that** [benefit or value I receive].

## Context & Background

<!-- Why does this story exist? What problem does it solve? Link to PRD if available. -->

[Context explaining the user need and how this story fits into the larger feature]

## Acceptance Criteria

<!-- Use Given/When/Then format. Each criterion should be independently testable. -->

### AC-1: [Criterion Title]

**Given** [initial context or precondition]

**When** [action taken by user]

**Then** [expected outcome]

### AC-2: [Criterion Title]

**Given** [initial context or precondition]

**When** [action taken by user]

**Then** [expected outcome]

### AC-3: [Criterion Title]

**Given** [initial context or precondition]

**When** [action taken by user]

**Then** [expected outcome]

## Edge Cases

<!-- Produced by the deliver-edge-cases skill, scoped to this story only (input validation, boundary conditions, error states, concurrency, integration failures). Keep each row to one scenario and its expected behaviour. For the feature-wide catalog, error messages and recovery paths, use the full deliver-edge-cases output and link it here. Omit rows that do not apply. -->

| Category | Scenario | Expected Behavior | Priority |
|----------|----------|-------------------|----------|
| [Input validation / Boundary / Error state / Concurrency / Integration] | [What goes wrong or sits at the limit] | [What the system does] | [P1/P2/P3] |
| [Category] | [Scenario] | [Expected behavior] | [P1/P2/P3] |

**Full edge-case catalog:** [link to deliver-edge-cases output, if one exists]

## Functional Requirements

<!-- Written by the technical-product-manager agent, not by the product manager. One row per observable behaviour the story needs, as a single testable MUST statement. N is the sprint number and k counts within it, so the IDs carry straight into the sprint spec (FR-<N>.<k>). Source cites where the requirement comes from: a PRD section or FR, a sprint story or acceptance criterion (S<N>-1/2 = story 1, second criterion), a constitution principle, or an assumption (A1). Until the technical-product-manager has filled it, write "To be filled by technical-product-manager". -->

| ID | Requirement | Source |
|---|---|---|
| FR-<N>.1 | <System> MUST <observable behaviour> | PRD §3 / S<N>-1/2 / Constitution III / A1 |

## Non-Functional Requirements

<!-- Written by the technical-product-manager agent. Performance, security, reliability, accessibility, data-integrity and similar qualities that apply to this story, as testable MUST statements with a source. Omit the table body with one line ("None for this story") rather than inventing rows. Do not add numeric targets the PRD leaves qualitative. -->

| ID | Requirement | Source |
|---|---|---|
| NFR-<N>.1 | <System> MUST <observable behaviour> | PRD §3 / S<N>-1/2 / Constitution III / A1 |

## Design Notes

<!-- Link to mockups, UX considerations, or design decisions -->

- [Design note or link to Figma]
- [UX consideration]

## Technical Notes

<!-- Implementation hints, technical constraints, or architectural considerations -->

- [Technical note]
- [Constraint or consideration]

## Dependencies

<!-- Other stories, external systems, or teams this story depends on -->

| Dependency | Type | Status |
|------------|------|--------|
| [Dependency 1] | [Story/API/Team] | [Blocked/Ready] |
| [Dependency 2] | [Story/API/Team] | [Blocked/Ready] |

## Out of Scope

<!-- Explicitly note what this story does NOT cover -->

- [Excluded item]
- [Excluded item]

## Open Questions

<!-- Unresolved questions that may affect implementation -->

- [ ] [Question 1]
- [ ] [Question 2]
