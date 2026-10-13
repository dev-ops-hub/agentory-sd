---
name: tracing-spec-coverage
description: Use when a sprint spec is drafted or revised and needs checking that every requirement, acceptance criterion and edge case has a test case, or when checking that a set of sprint specs covers every PRD requirement
---

# Tracing Spec Coverage

## Overview

Traceability is mechanical, so a script checks it; judgement is spent on the gaps it reports. **Core principle:** a requirement without a test case is a wish, and a sprint-plan criterion that no spec AC refines will be silently dropped.

## One spec

```bash
# a draft (the agent never writes it to a file): pipe it on stdin
python3 .claude/agents/technical-product-manager/skills/tracing-spec-coverage/scripts/check_spec.py - --plan SPRINT_FILE --sprint N <<'SPEC'
<spec>
SPEC
# a saved spec (the caller, after writing it)
python3 .../check_spec.py planning/specs/<track>-sprint-N.md --plan SPRINT_FILE --sprint N
```

It prints `OK` or one finding per line:

| Finding | Fix |
|---|---|
| `missing section` | Add it from the `writing-sprint-specs` template; "not applicable" in one line is fine |
| `FR-x: no Source` | Cite PRD §, story/criterion, constitution principle, or an `A<k>` assumption |
| `FR-x / AC-x / EC-x: no test case covers it` | Add a TC, or remove the requirement if no source supports it |
| `TC-x: covers undefined ...` | Typo, or the FR/AC/EC row is missing |
| `sprint plan criterion S3-1/2 is not refined` | Add an AC row with `S3-1/2` in **Refines** |
| `more than 3 clarification questions` | Keep the 3 with most scope/security/UX impact; make the rest `A<k>` assumptions |
| `Product decision` / `mark ... DONE` | See `writing-sprint-specs`: product gaps go to section 9; status markers belong to `sprintkit-sync` |

Paste the final output into section 10. If a finding stays because it is genuinely right (for example an FR verified only by review), keep it in section 10 with the reason.

## Across a sprint plan

When the caller asks for whole-plan coverage, read every spec in `planning/specs/` and the PRD's functional requirements, then return a table:

| PRD requirement | Specs and FR IDs that implement it | Status |
|---|---|---|
| PRD §6 FR-2 | sprint-3 FR-3.1, sprint-5 FR-5.4 | covered |
| PRD §6 FR-7 | — | **missing** |

A PRD requirement listed under Out of Scope or deferred to v2 is `deferred`, not `missing`.

## Common mistakes

- Making the script pass by adding a TC that only restates the FR. A TC names an exact input and an exact expected output.
- Counting a manual review as a test. Put it in section 7 as "Verified by: review", not as a TC.
