---
name: security-audit-methodology
description: Use when scoping a security audit of application code, frontend code, infrastructure-as-code, cloud architecture, CI/CD, or a running system — which scanners and checks to run for the target type, in what order, and when a finding needs threat modelling instead of a checklist
---

# Security Audit Methodology

## Overview

A security audit is evidence-first and read-only: find, verify, grade — never fix beyond an explicitly-requested narrow patch. **Core principle:** scope the checks and scanners to what the target actually is before running them — an API route, a Terraform module, and a frontend bundle fail in different ways, and running the wrong checklist against a target wastes the pass and still misses the real exposure.

## Scoping: pick checks by target type

| Target | Checks to run | Reference |
|---|---|---|
| Application code (API routes, business logic, data access) | Injection (SQL/shell/template/command), broken access control, auth/session handling, insecure deserialization, path traversal, crypto primitive choice, SSRF, sensitive-data exposure | `.claude/agents/software-engineer/skills/backend/application-security/SKILL.md` |
| Any code touching input, credentials, secrets, dependencies (baseline floor) | Parameterized queries, credential hashing, secret-free logging, least privilege, pinned/vetted dependencies, fail-closed error handling | `.claude/agents/shared-skills/secure-engineering/SKILL.md` |
| Frontend/browser code | XSS, CSRF (where cookies are used for auth), insecure client-side storage of tokens/secrets, dependency vulnerabilities in frontend packages, insecure `postMessage`/CORS handling | `.claude/agents/software-engineer/skills/backend/application-security/SKILL.md` for the shared OWASP vocabulary; route any frontend-specific fix to `frontend-developer` |
| IaC scripts (Terraform/OpenTofu, Bicep, CloudFormation, Pulumi) | Public network exposure, overly permissive ingress/egress, IAM/RBAC wildcard permissions, encryption at rest/in transit, unprotected or unencrypted state, module/provider version pinning, sensitive outputs, hardcoded secrets in variables/tfvars | `.claude/agents/devops-engineer/skills/infrastructure/infrastructure-as-code/SKILL.md` for correct structure, plus the Policy as Code section of `infrastructure-hardening` for the checkov/tfsec/conftest checks |
| Cloud architecture/config (once provider is identified) | Provider-specific identity, network, encryption and logging controls — see Cloud provider inference below | `.claude/agents/devops-engineer/skills/cloud/{azure,aws,gcp}/SKILL.md` |
| Containers, Kubernetes manifests, network policy | CIS benchmark gaps, container/pod hardening, network segmentation, policy-as-code | `.claude/agents/devops-engineer/skills/security/infrastructure-hardening/SKILL.md` |
| Secrets management, workload identity, certs | Vault/cloud secret manager usage, mTLS, least-privilege IAM for a workload | `.claude/agents/devops-engineer/skills/security/secrets-and-identity/SKILL.md` |
| CI/CD pipeline, build artifacts, dependency supply chain | SBOM presence, artifact signing, provenance, vulnerability-scan gating | `.claude/agents/devops-engineer/skills/cicd/supply-chain-security/SKILL.md` |
| Dockerfile / image build | Base image choice, layer hygiene, non-root user, build-time secret leakage | `.claude/agents/devops-engineer/skills/containers/docker/SKILL.md` |

Read the referenced skill for the depth of each check; this skill only says which to load. Most audits touch two or three rows, not all of them — an audit of a FastAPI endpoint does not need the Kubernetes row.

## Cloud provider inference

Infer the provider from the artefacts (Terraform provider blocks, SDK imports, resource naming, CI deploy targets) rather than asking or guessing. Load only the matching cloud skill (`azure`, `aws`, or `gcp`) — loading all three speculatively wastes the pass. Absence of a specific control (e.g. no WAF) is not automatically a finding; evaluate it against actual exposure (is the resource internet-facing, does it handle sensitive data) before deciding it's a gap worth reporting.

## Deterministic scanners before semantic review

Where the tool is available (check with e.g. `command -v`), run a scanner before relying on judgment alone — scanners catch what pattern-matching misses and anchor findings in reproducible evidence:

| Scanner | Target |
|---|---|
| `semgrep` | Application code SAST (injection, insecure patterns) |
| `trivy` | Containers, filesystem, IaC misconfiguration, known-vulnerability scanning |
| `checkov` | Terraform/CloudFormation/Kubernetes/Bicep misconfiguration |
| `gitleaks` | Secrets committed to the repo or its history |
| `syft` | SBOM generation for a dependency tree |
| `grype` | Known-vulnerability matching against an SBOM or image |

A missing tool is not a blocker: note it in the report's "Not checked" section and fall back to semantic review for that pass rather than skipping it silently. Never install or mutate anything to make a scanner available — Bash is for running and inspecting, not provisioning.

Treat every scanner hit as evidence requiring verification, not a finding to reproduce verbatim:
1. Read the actual flagged location and confirm the condition the scanner claims actually holds.
2. Determine whether an exploitable or materially risky path actually reaches it (an unreachable dead code path, a value already validated upstream, or a compensating control downstream can make a textbook-severity hit a non-issue or a lower one).
3. Correlate duplicate hits from multiple scanners on the same root cause into one finding.
4. Decide status: Confirmed (verified exploitable/risky), Probable (likely but not fully traced), Observation (real but not a vulnerability — e.g. a style/best-practice gap), or False Positive (scanner wrong or condition not reachable) — see `reporting-security-findings` for the full schema.

Never silently drop a scanner finding — a dismissed one is reported as a False Positive with the reason, not omitted.

## Semantic review

Scanner coverage is not sufficient on its own. After the deterministic pass, review what scanners structurally can't see: trust boundaries, privilege-escalation paths, authorization logic (not just presence of a check, but whether it checks the right thing), cross-service trust assumptions, insecure defaults, and dangerous combinations of individually-valid configurations (e.g. a public subnet plus a security group that's fine alone, combined with a role that's fine alone, that together expose a database).

## Threat modelling

Reach for this when a finding can't be assessed meaningfully from an individual configuration setting alone — i.e. the risk is in how components interact, not in any one file. Identify assets, actors, entry points, trust boundaries, identities, data flows, privileged components, and external dependencies; STRIDE is a reasonable default structure when a methodology helps. Keep it proportionate: a narrowly-scoped review (one endpoint, one module) does not need a full threat model, and building one anyway is wasted effort that delays the actual findings.

## Order of operations

1. Identify the target type(s) from what was actually dispatched (a diff, a file set, a running service, "the whole repo") — don't assume application code if the dispatch names infra, frontend, or cloud config, and don't skip the baseline row even when a more specific row also applies.
2. Load only the rows (and, for cloud, only the inferred provider) that match. Read the referenced skill fully before judging against it — a half-remembered checklist produces both false positives and missed findings.
3. Run available deterministic scanners for the matched rows; verify every hit against the actual code before trusting it.
4. Walk the code/config/manifests against each loaded checklist for what scanners can't see. For code review, read the actual data flow (where does this input come from, where does it end up) rather than pattern-matching function names.
5. Apply threat modelling where a finding needs it (see above) rather than forcing every finding into a single-file checklist frame.
6. Grade every finding per `reporting-security-findings` before writing the report — severity, status, and ownership are not optional, even under a "just the critical ones" request.

## Common mistakes

| Mistake | Fix |
|---|---|
| Running the application-security checklist against Terraform | Match the row to the actual target; IaC scripts need the IaC row, not the application-code row |
| Treating "no `.tf` files changed" as no IaC to audit when the dispatch is "the whole repo" | Glob for IaC file extensions (`.tf`, `.tfvars`, `.bicep`, CloudFormation YAML/JSON, Pulumi source) across the whole scope, not just the diff |
| Loading all three cloud skills (azure/aws/gcp) "to be safe" | Infer the provider from the artefacts first; load only the matching one |
| Reproducing scanner output as findings without reading the flagged code | Every scanner hit is verified against the actual location before it becomes a finding |
| Concluding IaC is secure because Checkov/Trivy reported nothing | Scanners catch known misconfiguration patterns, not architectural combinations or logic errors — still run the semantic pass |
| Building a full STRIDE threat model for a one-endpoint review | Scale the model to the scope; most reviews don't need one |
| Fixing the vulnerability instead of reporting it | This agent only patches when explicitly requested and narrowly scoped; otherwise findings go back to `software-engineer`, `frontend-developer`, or `devops-engineer` to remediate |
| Skipping the baseline secure-engineering row because a more specific row (application-security) was already loaded | Load both — the baseline catches generic issues (logging, dependency pinning) the specific row doesn't restate |
