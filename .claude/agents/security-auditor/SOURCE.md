# Source

The `security-auditor` agent's own skill library (`skills/security-audit-methodology/`, `skills/reporting-security-findings/`) is written for this repository. Its content is original — informed by a user-supplied security-auditor prompt (persona, severity/status/confidence schema, scanner list, cloud-provider sections, report structure) that was reviewed, cross-checked against the skills already present in this repo, and reworked into this repo's skill format rather than copied verbatim.

| Skill | Origin | License | Notes |
|---|---|---|---|
| security-audit-methodology | Written for this repository | Same terms as this repository | Scoping table, deterministic-scanner-then-semantic-review order, cloud-provider inference, and when to reach for threat modelling. Scanner list (Semgrep, Trivy, Checkov, Gitleaks, Syft, Grype) and the STRIDE/threat-modelling trigger are drawn from the user-supplied prompt; the per-target-type routing to existing agents' skills instead of a duplicate checklist is this repo's own design |
| reporting-security-findings | Written for this repository | Same terms as this repository | Finding schema (ID/Title/Status/Severity/Confidence/Affected component/Evidence/Risk/Attack path/Existing controls/Recommendation/Reference/Owner) and report structure (executive summary → scope → tools used → verdict → findings → false positives → limitations → remediation sequence) are drawn from the user-supplied prompt; severity table, "under pressure" rationalization table and red flags follow this repo's `reporting-audit-findings` (`../product-auditor/skills/reporting-audit-findings/SKILL.md`) convention, adapted from PRD-audit grading to vulnerability grading |
| secure-engineering | Pointer only — content lives in `../shared-skills/secure-engineering/` | See `../shared-skills/SOURCE.md` | This agent's copy is a `SKILL.md` pointer per this repo's shared-skill convention; no content duplicated here |

This agent does not duplicate skills already owned by another agent. It reads them directly, in place:

| Referenced skill | Owned by | Path |
|---|---|---|
| application-security | software-engineer | `../../software-engineer/skills/backend/application-security/SKILL.md` |
| infrastructure-as-code | devops-engineer | `../../devops-engineer/skills/infrastructure/infrastructure-as-code/SKILL.md` |
| infrastructure-hardening | devops-engineer | `../../devops-engineer/skills/security/infrastructure-hardening/SKILL.md` |
| secrets-and-identity | devops-engineer | `../../devops-engineer/skills/security/secrets-and-identity/SKILL.md` |
| supply-chain-security | devops-engineer | `../../devops-engineer/skills/cicd/supply-chain-security/SKILL.md` |
| docker | devops-engineer | `../../devops-engineer/skills/containers/docker/SKILL.md` |
| azure / aws / gcp | devops-engineer | `../../devops-engineer/skills/cloud/{azure,aws,gcp}/SKILL.md` |

## Design origin

This agent and its skill library were built in response to a user-supplied Security Auditor system prompt (persona, role boundaries vs. `software-engineer`/`frontend-developer`/`devops-engineer`, audit workflow, deterministic-scanner-first methodology, cloud-provider sections, finding classification schema, severity rules, false-positive handling, and output structure). The prompt was decomposed rather than pasted in wholesale:

- Role boundary, "assurance not implementation," and routing remediation to the owning agent → folded into `../../security-auditor.md` directly, matching this repo's existing `product-auditor` pattern (an auditor role separate from the agents that author the artifact it reviews).
- Scanner list, scoping-by-target-type, cloud-provider inference, and threat-modelling trigger → `skills/security-audit-methodology/SKILL.md`.
- Finding schema and report structure → `skills/reporting-security-findings/SKILL.md`.
- Shared security-engineering knowledge the prompt asked for (secrets, dependency security, input validation, auth patterns, logging, crypto, TLS, SBOM) → not re-created; routed to the skills that already cover this ground in this repo (`shared-skills/secure-engineering`, `software-engineer/skills/backend/application-security`, and the `devops-engineer` security/cloud skills listed above), since the prompt's own instruction was "do not duplicate these skills under the Security Auditor."

## Testing

No baseline (RED) pressure-testing with subagents has been run against `security-audit-methodology` or `reporting-security-findings`. Both are reference/technique skills (scoping tables, a report schema) rather than discipline-enforcing skills with a demonstrated rationalization pattern to bulletproof against, so per `superpowers:writing-skills`' "Match the Form to the Failure" guidance they were written as structural/positive-recipe content rather than prohibition-heavy content. That said, the Iron Law still calls for a failing-test-first pass before relying on this in a real audit: a baseline run (no skill, pressure scenario: "just the criticals," "it's already patched," "skip the Terraform, we're out of time") against each skill is the natural next step before treating this agent's output as load-bearing.
