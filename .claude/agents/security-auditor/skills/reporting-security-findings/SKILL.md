---
name: reporting-security-findings
description: Use when returning the result of a security audit, including re-audits after remediation, and especially when the caller asks for a quick sign-off, "only criticals", or says the vulnerability was already fixed
---

# Reporting Security Findings

## Overview

The report is the contract between auditor, remediator and user. **Core principle:** every finding is graded by actual exploitability and impact, carries the evidence that justifies the grade, and is owned by whoever can close it; time pressure changes the length of the prose, never the grade, the status, or whether a finding is reported at all.

## The report

Return exactly these parts, in order:

1. `Constitution: v<version> read` (or `none`) if `planning/constitution.md` exists in this project
2. **Executive summary**: 2-4 sentences — what was audited, overall risk posture, the single most important thing to fix first
3. **Audit scope**: exactly what was reviewed (paths, diff, PR) and what was explicitly out of scope
4. **Technologies assessed**: languages, frameworks, cloud provider(s), IaC tool(s) actually found in scope
5. **Tools used**: which scanners actually ran (and their versions/flags if relevant) vs. which were unavailable and why
6. **Verdict:** `BLOCK` (any open Confirmed/Probable Critical or High), `REVISE` (no Critical/High, any open Medium), `PASS` (only Low, Observation, or nothing open)
7. **Findings**, most severe first, grouped by severity. Each one:
   - **ID** `S1`, `S2`, ... stable across rounds
   - **Title**: clear, specific description of the vulnerability or weakness
   - **Status**: `Confirmed` (verified exploitable/risky by reading the actual code or config) / `Probable` (strong evidence, not fully traced to an exploit path) / `Observation` (real but not itself a vulnerability — a hardening gap or best-practice deviation) / `False Positive` (a scanner or pattern match that doesn't hold up — report it here, never by silent omission)
   - **Severity**: Critical/High/Medium/Low (Informational for pure Observations) — see Severity below
   - **Confidence**: High/Medium/Low — how sure the evidence makes you, independent of severity
   - **Affected component**: file/path and line, resource/module name, pipeline, API endpoint, or service
   - **Evidence**: the concrete code, config, or scanner output that supports the finding — quote it, don't just describe it
   - **Risk**: what could happen and under what conditions
   - **Attack or failure path**: how this is realistically reached or abused, step by step — what input or access it takes
   - **Existing controls**: mitigations already present that reduce (but may not eliminate) the risk
   - **Recommendation**: the smallest effective fix, concrete enough to apply (a config example or code snippet where useful) — never a bare "improve security"
   - **Reference**: OWASP/CWE/CIS/vendor-doc mapping where one applies
   - **Owner**: `software-engineer` (application/backend), `frontend-developer` (browser/UI), `devops-engineer` (IaC/cloud/container/CI/CD), or `USER` (a policy or risk-acceptance decision only the user can make, e.g. accepting a known-vulnerable dependency with no available fix)
8. **False positives / dismissed findings**: every scanner hit that was investigated and dismissed, with the reason — never silently dropped
9. **Closed since last round** (round 2+): IDs verified fixed by re-reading the actual code/config, never because the caller says it was fixed
10. **Limitations / not checked**: what was out of scope, unverifiable, or skipped because a tool was unavailable, and why
11. **Prioritised remediation sequence**: the findings in the order they should actually be fixed (not just severity order — a Critical blocked on a High dependency goes after it)

## Severity

| Severity | Meaning | Always this severity |
|---|---|---|
| Critical | Exploitable now, by an unauthenticated or low-privilege actor, for high impact | Remote code execution, auth bypass, SQL/command injection reachable from untrusted input, hardcoded production credential, secret committed to the repo |
| High | Exploitable with some precondition, or lower-impact but still a real breach | Broken access control on a sensitive action, SSRF, missing encryption for sensitive data at rest/in transit, privilege escalation path |
| Medium | Weakens defense but needs another flaw or significant effort to exploit | Missing rate limiting, verbose error leaking stack traces, outdated dependency with no known active exploit, weak-but-not-broken crypto configuration |
| Low | Defense-in-depth / hardening gap | Missing security headers, overly broad IAM scope with no demonstrated path to abuse, missing SBOM |

Severity considers exploitability, exposure, required privileges, attack complexity, data sensitivity, blast radius, existing controls, likelihood, and business impact together — never from scanner severity or CVSS alone. CVSS is a useful input, not the only risk measure: a CVSS 9.8 CVE in a dependency that's never invoked on a reachable path is not automatically Critical in this codebase, and a CVSS 5 misconfiguration that chains with another to reach a production database might be. Grade by exploitability and impact as they actually are here, not by category reputation — a textbook-"critical" bug class (e.g. XSS) reachable only from an admin-only internal tool with no untrusted input is not automatically Critical; state the reasoning when a finding's grade might look surprising.

Do not inflate severity, and do not claim exploitability without evidence — "Confirmed" requires having actually traced the path, not assumed it from the vulnerability class.

## Under pressure

"Quick sign-off", "just the criticals", "that one's already patched", "it's an internal tool so it doesn't matter": none of these change a finding's severity, status, or owner. Keep the prose short instead.

| Excuse | Reality |
|---|---|
| "It's an internal tool, lower the severity" | Internal-only reduces likelihood, not impact — grade on what happens if it's reached, and note the internal-only context in Risk |
| "They said it's already fixed, skip re-checking" | Re-audits confirm fixes by re-reading the code; never close on the caller's word alone |
| "This is a known CVE with no patch, just note it and move on" | Still a finding with a severity; owner is `USER` for the risk-acceptance call, not silently dropped |
| "Only report what's exploitable today" | Medium/Low defense-in-depth gaps and Observations are still findings — omitting them is not the same as grading them Low |
| "The scanner flagged it, that's enough to report" | Verify against the actual code first; an unverified scanner hit reported as Confirmed is a fabricated finding |
| "I'll just drop the ones that don't look real" | Dismissed hits go in False positives / dismissed findings with the reason — never silently removed |

**Red flags (stop and re-grade):** downgrading a finding because the target is "internal" or "temporary", fixing the vulnerability yourself instead of reporting it (unless a narrow patch was explicitly requested), closing a finding without re-reading the code, grouping findings as "nice to have" instead of grading them, marking something Confirmed without having traced the actual path, omitting a scanner hit instead of recording it as a dismissed False Positive.

## Re-audits

From round 2: re-read the actual code/config; close a finding only after confirming the fix firsthand; look for regressions the fix introduced (a new injection point, a secret moved but not rotated); keep IDs stable.
