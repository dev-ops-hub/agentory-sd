# Source

The `devops-engineer` agent's skill library (`skills/`) is written for this repository, following the same precedent as `software-engineer` and `solution-architect`'s `multi-cloud-architect`: external repositories were researched for scope and quality calibration, not vendored verbatim.

| Skill | Origin | License | Notes |
|---|---|---|---|
| cicd/cicd-architecture | Written for this repository | Same terms as this repository | Topic coverage (stage design, promotion gates, rollout strategies, rollback) informed by `wshobson/agents`' `deployment-pipeline-design` (MIT) for scope; no text copied |
| cicd/github-actions | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `github-actions-templates` (MIT) and `agentic-awesome-skills`' `github-actions`/`github-actions-advanced` (MIT, re-exported from BagelHole/DevOps-Security-Agent-Skills) for scope |
| cicd/gitlab-ci | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `gitlab-ci-patterns` (MIT) and `agentic-awesome-skills`' `gitlab-ci`/`gitlab-ci-patterns` (MIT) for scope |
| cicd/supply-chain-security | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `sbom-supply-chain`/`supply-chain-security` (MIT) for scope (SBOM, signing, provenance) |
| infrastructure/infrastructure-as-code | Written for this repository | Same terms as this repository | Terraform-primary structure informed by `wshobson/agents`' `terraform-module-library` (MIT) and `agentic-awesome-skills`' `terraform-aws`/`terraform-specialist`/`opentofu-migration` (MIT) for scope; Bicep/CloudFormation/Pulumi reference files informed by `agentic-awesome-skills`' `arm-templates`/`cloudformation` entries (MIT) for scope. Terraform docs in this skill now follow the same SKILL+README+EXAMPLES shape as `luxor-devops-suite`'s `terraform-infrastructure`, while retaining repository-authored wording and guardrails |
| containers/docker | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `docker-expert`/`docker-compose`/`container-hardening` (MIT) for scope |
| containers/kubernetes (+ references/) | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `gitops-workflow`/`k8s-security-policies`/`helm-chart-scaffolding` (MIT) and `agentic-awesome-skills`' `kubernetes-architect`/`k8s-security-policies`/`helm-charts` (MIT) for scope; one consolidated skill with per-topic reference files, not split into 4+ separate skills as some sources do |
| cloud/aws | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `aws-vpc`/`aws-iam`/`aws-cost-optimization` (MIT) for scope. Deliberately operational, not provider-selection content (that stays in `solution-architect`'s `multi-cloud-architect`) |
| cloud/azure | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `azure-aks`/`azure-networking` (MIT) for scope |
| cloud/gcp | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `gcp-gke`/`gcp-networking` (MIT) for scope |
| networking/infrastructure-networking | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `hybrid-cloud-networking` (MIT) for scope |
| observability/observability-platforms | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `grafana-dashboards`/`prometheus-configuration` (MIT) and `luxor-devops-suite`'s `observability-monitoring` (MIT per `plugin.json`, used for scope signal only — see Research basis) for scope; one consolidated skill, not split per-tool |
| reliability/sre-and-reliability | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `incident-runbook-templates`/`postmortem-writing`/`slo-implementation` (MIT) and `agentic-awesome-skills`' `incident-management` (MIT) for scope; one consolidated skill covering SLO, incident response, runbooks, postmortems and DR, not split into 4+ skills |
| security/secrets-and-identity | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `hashicorp-vault`/`aws-secrets-manager`/`azure-keyvault`/`gcp-secret-manager` (MIT) for scope |
| security/infrastructure-hardening | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `policy-as-code`/`cis-benchmarks`/`kubernetes-hardening` (MIT) for scope |
| troubleshooting/infrastructure-troubleshooting | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `connectivity-triage` (MIT) for the fault-domain isolation method; specializes `shared-skills/systematic-debugging` for infrastructure fault domains rather than duplicating its base methodology |

Shared skills used by this agent (`systematic-debugging`, `secure-engineering`, `testing-principles`, `engineering-documentation`, `develop-adr`, `git-workflow`, `problem-decomposition`, `code-review`): origin, version and license are in [`../shared-skills/SOURCE.md`](../shared-skills/SOURCE.md). This agent does not use `test-driven-development` or `deliver-*` (PM-sourced) shared skills — see Role boundary rationale below.

## Research basis

Three reference repositories were researched for candidate content, licensing and quality before writing any skill:

| Repo | License found | Verdict |
|---|---|---|
| [wshobson/agents](https://github.com/wshobson/agents) | MIT (root `LICENSE`) | Reusable with attribution. Well-structured `SKILL.md` + `references/*.md` convention matching this repo's own; agent persona files are generic capability lists, not reused — the `skills/*/SKILL.md` + `references/` content was the useful scope reference, no verbatim text taken |
| [manutej/luxor-claude-marketplace](https://github.com/manutej/luxor-claude-marketplace) (`plugins/luxor-devops-suite/skills`) | MIT per `luxor-devops-suite`'s own `plugin.json`, but no repo-root `LICENSE` file exists | Used as a structure and coverage signal. Terraform docs here align to the same high-level document split (`SKILL.md`, `README.md`, `EXAMPLES.md`) as `terraform-infrastructure`, while preserving this repo's authored wording, tighter operational guardrails, and reference-file split for maintainability |
| [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills) | MIT (root `LICENSE`); DevOps content mostly re-exports [BagelHole/DevOps-Security-Agent-Skills](https://github.com/BagelHole/DevOps-Security-Agent-Skills) (also MIT) | Reusable with attribution. Broad, consistently concrete coverage (Vault, SBOM/supply-chain, policy-as-code, platform engineering, incident SEV-levels) — used for topic/scope reference across most skills in the table above, no verbatim text taken |

## Role boundary rationale

- `test-driven-development` (shared skill) is not used here: infrastructure changes are validated by `plan`/`what-if`/dry-run review and staged rollout, not a red-green unit-test cycle — see `skills/testing-principles` (shared) for how validation depth is scoped instead.
- `develop-adr` is used: the project constitution requires ADRs for PRD §8 architecture decisions (IaC tool, cloud provider operational pattern, CI platform), the same category of decision this agent implements.
- No genuinely new shared skill emerged from DevOps-specific research — infrastructure topics (Terraform, Kubernetes, cloud operations) don't generalize to application or frontend code, so none were promoted to `shared-skills/`.

## Responsibility matrix (abridged)

| Capability | Shared | Software Engineer | DevOps |
|---|---|---|---|
| Git fundamentals / debugging / docs / code review | ✓ | ✓ | ✓ |
| Application business logic / API implementation | | OWN | |
| Application tests, app-level security code | | OWN | |
| Terraform / IaC | | | OWN |
| CI/CD pipeline platform | | Partial (build/test commands) | OWN |
| Docker | | Partial (Dockerfile, runtime requirements) | OWN |
| Kubernetes operations | | | OWN |
| Application instrumentation (metrics/log/trace code) | | OWN | Partial (platform) |
| Observability platform | | | OWN |
| Cloud infrastructure (operational) | | | OWN |
| Infrastructure security | | Partial (app secrets usage) | OWN |
| System/cloud architecture design, provider selection | | | (solution-architect owns; DevOps implements) |

## Refreshing

Every skill here is written for this repository, not vendored — refresh directly by editing the skill/reference files when tools, cloud services or practices change, and record the change in this file's table, not a separate changelog.
