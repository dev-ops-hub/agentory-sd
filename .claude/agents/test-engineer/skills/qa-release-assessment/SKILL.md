---
name: qa-release-assessment
description: Use when returning a go/no-go recommendation on a release, sprint, or merge - the QA gate that weighs coverage, defects, and residual risk into PASS/PASS_WITH_RISK/FAIL/BLOCKED, including re-assessments after fixes and especially when the caller asks for a quick sign-off or says it's already fixed
---

# QA Release Assessment

## Overview

The release assessment is the contract between QA, the team, and whoever decides to ship. **Core principle:** the verdict is earned by evidence already gathered through this agent's other skills (acceptance testing, regression testing, requirements traceability, defect triage) — this skill is where that evidence gets weighed into one recommendation, not where new testing happens.

## When to Use

- Before a release, merge, or sprint sign-off
- Re-assessing after defect remediation
- The caller asks for "just tell me if it's ready," "quick sign-off," or says a known defect is "already fixed"

## Inputs to Gather First

Before writing the assessment, pull the actual numbers from the other skills — do not estimate them:

- Requirements coverage from `../requirements-traceability/SKILL.md` (Passed/Failed/Blocked/Untested counts)
- Acceptance-criteria verdicts from `../acceptance-testing/SKILL.md`
- Automated test results — VERIFIED per `../test-evidence/SKILL.md`, this session, not a remembered prior run
- Open defects from `../defect-triage/SKILL.md`, with current severity
- Flaky tests currently known, and whether they've been investigated or just tolerated
- Regression results from `../regression-testing/SKILL.md` for anything touched
- Accessibility findings, if UI scope — read `../../../ux-designer/skills/a11y-audit/SKILL.md` directly rather than duplicating it (this agent does not own accessibility auditing, only its functional-verification slice)
- Security-auditor status, if a security review was in scope — reference `security-auditor`'s verdict; this agent cannot substitute its own judgment for that review
- Performance findings, only if the PRD/constitution stated a threshold (per `../test-strategy/SKILL.md`'s conditional treatment)

## Verdict

| Verdict | Criteria |
|---|---|
| **PASS** | All in-scope requirements Passed; no open Critical/High-severity defects; no unexplained flaky tests on the critical path |
| **PASS_WITH_RISK** | Core requirements Passed, but a named residual risk remains (a deferred Medium/Low defect, an untested non-critical requirement, a flaky test under active investigation) — ship is possible, risk is explicit, not hidden |
| **FAIL** | A requirement Failed, or an open Critical/High defect exists on in-scope functionality |
| **BLOCKED** | Testing could not be completed — missing environment, missing dependency, missing test data, or a prerequisite defect blocks further testing |

A verdict is never softened because a deadline is close, because the author says it's already fixed, or because the caller asks for "just the blockers" — see Under Pressure below.

## Report Format

```
QA ASSESSMENT

Release / scope:
Environment:
Build / commit:

Overall: PASS | PASS_WITH_RISK | FAIL | BLOCKED

Requirements
  Passed:    N
  Failed:    N
  Blocked:   N
  Untested:  N

Tests
  Total:   N
  Passed:  N
  Failed:  N
  Skipped: N
  Flaky:   N

Critical / High defects (open)
  [ID, title, severity, owner — from defect-triage]

Regression findings
  [scope tested, result]

Non-functional findings
  [accessibility / performance, if in scope — cite the owning skill's output, don't re-derive]

Security Auditor status
  [verdict cited from security-auditor, or "not in scope for this assessment"]

Residual risks
  [named explicitly — this is what makes PASS_WITH_RISK different from PASS]

Recommendation
  [one or two sentences, consistent with the Overall verdict above]
```

Every number in this report must be VERIFIED or explicitly INFERRED per `../test-evidence/SKILL.md` — never a round estimate presented as a count.

## Under Pressure

| Excuse | Reality |
|---|---|
| "Just tell me if it's ready" | The verdict already answers that; the breakdown is what makes it checkable. Shortening prose is fine; dropping the breakdown is not. |
| "Only the blockers matter right now" | PASS_WITH_RISK exists for exactly this — name the non-blocking residuals instead of omitting them. |
| "The author says that defect is fixed" | Re-verify per `../regression-testing/SKILL.md` before closing it in this assessment — a claimed fix is not a verified fix. |
| "We're almost out of time, round up to PASS" | The verdict table above has no time-pressure exception. State the actual verdict; the business can decide to ship anyway, but not by changing what QA reported. |
| "It's a small defect, don't mention it" | Every open defect in scope appears in the report at its real severity — small-and-omitted is how residual risk becomes a surprise later. |

**Red flags (stop and re-grade):** rounding PASS_WITH_RISK up to PASS to avoid an awkward conversation, omitting an open defect because it's "probably fine," marking a requirement Passed because the author says the fix landed without re-running the check, letting "we need to ship" change the Overall verdict instead of staying in the Recommendation line.

## Re-Assessments

From round 2 onward: re-pull every input fresh (do not reuse round 1's numbers), close a defect only after `../regression-testing/SKILL.md` confirms the fix, and check for new regressions the fix introduced — a fix that closes one defect while opening another is not progress toward PASS.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Writing the assessment from memory of "how testing generally went" | Pull fresh numbers from each owning skill's actual output |
| Treating the verdict as negotiable under deadline pressure | The verdict is derived from the table; only the prose length is negotiable |
| Silently dropping Untested requirements from the count | Report them — they're a residual risk, not a non-issue |
| Re-approving a previously-FAIL verdict because "it's probably fixed now" | Re-run regression; only a verified fix changes the verdict |

## Quick Reference

| Situation | Verdict |
|---|---|
| Everything passes, nothing open | PASS |
| Core passes, named non-blocking residual risk | PASS_WITH_RISK |
| A requirement fails, or a Critical/High defect is open | FAIL |
| Testing itself couldn't complete | BLOCKED |
