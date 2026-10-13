# Spec: Sprint <N> — <name>

**Track:** <track>  **Stories:** S<N>-1, S<N>-2  **Status:** draft | ready
**Sources:** <PRD file> §<..>; <sprint file> Sprint <N>; constitution v<X.Y.Z> | none
**Depends on:** Sprint <M> (<what this sprint uses from it>) | none
**Touches:** <copied from the sprint plan; never wider>

<!-- Status is "ready" only when section 9 has no open Q or C. -->

## 1. User scenarios

<Who uses what this sprint delivers, and why. Primary flow, then alternates. No implementation detail.>

## 2. Functional requirements

| ID | Requirement | Source |
|---|---|---|
| FR-<N>.1 | <System> MUST <observable behaviour> | PRD §3 / S<N>-1/2 / Constitution III / A1 |

**Success criteria:** <measurable outcomes for the sprint, technology-agnostic>

## 3. Interfaces and data

<Exact signatures, types and data shapes, reusing dependency sprints' names. Files created or changed, all inside Touches.>

## 4. Acceptance criteria

| ID | Refines | Given / When / Then | Covers |
|---|---|---|---|
| AC-<N>.1 | S<N>-1/1 | Given <state>, when <action>, then <result> | FR-<N>.1 |

## 5. Edge cases

| ID | Category | Condition | Expected behaviour | Source |
|---|---|---|---|---|
| EC-<N>.1 | Input boundary | <condition> | <behaviour> | FR-<N>.2 / A1 |

## 6. Test cases

| ID | Type | File | Input / steps | Expected | Covers |
|---|---|---|---|---|---|
| TC-<N>.1 | unit / property / integration / e2e | <path> | <exact input> | <exact output> | FR-<N>.1, AC-<N>.1 |

## 7. Constitution and non-functional checks

| Principle / NFR | How this sprint meets it | Verified by |
|---|---|---|
| I. <name> | <concrete rule for this sprint> | TC-<N>.<k> / review check |

## 8. Out of scope

- <item> (<where it lives instead: Sprint M, v2, PRD §10>)

## 9. Open items

- **Q1** [NEEDS CLARIFICATION] <question> — options: <A / B>; impact: <scope / security / UX>
- **A1** ASSUMPTION <default> — because <reason>; if wrong: <what changes>
- **D1** DECISION <internal engineering choice> — <rationale>
- **C1** CONFLICT <source X says ...> vs <source Y says ...>

## 10. Coverage

<Output of check_spec.py: "OK" or the remaining findings with a reason each.>
