---
name: multi-cloud-architect
description: >-
  Use when designing, reviewing or comparing cloud architectures on Azure, AWS or GCP —
  selecting services, applying design patterns, evaluating networking/IAM/HA-DR/cost
  tradeoffs, running a Well-Architected-style review, or comparing providers for a
  requirement. Detects the provider from the request; asks when it's ambiguous and
  material to the recommendation.
---

# Multi-Cloud Architect

## Overview

Design and review well-architected cloud systems on Azure, AWS, or GCP. This skill
reasons natively per provider — it does not translate one provider's services onto
another by name-matching. It provides provider-neutral architecture principles, 44
cloud design patterns, decision frameworks, and security guidance, plus a dedicated
reference for each provider's services, identity model, networking model, and
well-architected framework.

## Provider Detection

Before reasoning about services, establish the provider:

1. **Explicit** — the user names Azure, AWS, or GCP (or a specific service: AKS, Lambda,
   Cloud Run, Entra ID, IAM, VPC...). Load only that provider's reference. Do not mention
   or suggest the other two providers unless the user asks for a comparison or asks about
   portability.
2. **Multiple named** — the user names 2+ providers, or asks to compare / migrate /
   go multi-cloud. Load all providers referenced and use the Comparison Workflow below.
3. **Ambiguous** — no provider named, no provider-specific service named, and the choice
   of provider would change the recommendation (it almost always does — service names,
   identity model, and network model differ). Ask which provider before proceeding. Do
   not default to one provider silently.
4. **Ambiguous but immaterial** — the question is about a cross-cloud concept (e.g. "what
   is the Saga pattern?", "how should I think about blast radius?"). Answer from
   `references/architecture-principles.md` or `design-patterns.md` without asking.

Do not infer a provider from weak signals (a `.tf` file extension, a generic term like
"cluster" or "function") when the request itself doesn't name one — ask instead.

## Do Not Assume

Azure, AWS, and GCP are not the same architecture with different labels. Before giving
advice, check it isn't one of these common false generalizations:

- **Identity has no 1:1 mapping.** Azure's Entra ID is a single unified identity
  platform for users and workloads. AWS splits workforce identity (IAM Identity Center /
  external IdP) from resource permissions (IAM). GCP splits Cloud Identity (users) from
  IAM (permissions) and Workload Identity Federation (external workloads). Don't say
  "AWS's equivalent of Entra ID is IAM."
- **The managed-service escalation ladder is provider-specific.** Azure's VM→App
  Service→AKS progression, AWS's EC2→Fargate→Lambda progression, and GCP's Compute
  Engine→Cloud Run→GKE Autopilot progression don't line up service-for-service.
- **Virtual network scope differs by provider.** Azure VNets and AWS VPCs are regional
  resources. A GCP VPC is global by default (subnets are regional, routing is global).
  This changes hub-and-spoke and multi-region topology defaults, not just terminology.
- **Multi-region write support is a per-service fact, not a cloud-wide rule.** Azure SQL
  is active-passive only; GCP Spanner supports strongly-consistent multi-region writes
  natively; AWS's answer depends on the specific database chosen (Aurora Global Database
  vs DynamoDB global tables behave differently). Check the specific service.
- **"Well-Architected" pillar sets differ.** Azure WAF has 5 pillars; AWS Well-Architected
  has 6 (adds Sustainability); the Google Cloud Architecture Framework has its own 5.
  Don't score a GCP design against "the 5 WAF pillars" as if that's a universal standard.
- **Managed identity / IAM roles / service accounts reach "no stored credentials"
  through different mechanisms and different default-risk postures** (GCP's default
  service account over-privilege is a known trap the other two don't share the same way).
- **Provider-branded tools are not drop-in equivalents.** Azure Chaos Studio, Advisor,
  Cost Management vs. AWS Fault Injection Simulator, Trusted Advisor, Cost Explorer vs.
  GCP's Recommender have different scope and maturity — don't assume feature parity.

## Workflow

1. **Detect the provider** (above). Load exactly one of `references/azure.md`,
   `references/aws.md`, `references/gcp.md` — unless comparing, then load all named.
2. **Identify requirements** before reaching for services: functional need, availability
   target, latency, throughput, data residency/compliance, RTO/RPO, cost ceiling, team
   skills. State assumptions explicitly when the brief doesn't cover one.
3. **Reason across these areas**, using the loaded provider reference for service choice
   and `references/architecture-principles.md` + `references/security.md` for the
   provider-neutral judgment: networking, identity and access management, compute,
   containers/Kubernetes, serverless, storage, databases, API management, integration and
   messaging, observability, security, secrets/key management, high availability, disaster
   recovery, DevSecOps/CI-CD, infrastructure as code, governance, cost optimization.
4. **Select patterns** from `references/design-patterns.md` (44 cloud design patterns,
   provider-neutral) for the concerns identified in step 3.
5. **Validate** against the provider's own well-architected framework (named per-provider
   in that provider's reference) and the neutral tradeoff matrix in
   `references/decision-frameworks.md`.
6. **Document decisions** that are costly to reverse as ADRs (context, decision,
   consequences).

## Comparison Workflow

When asked to compare providers or evaluate multi-cloud / portability, do not jump to a
service-name table. Follow `references/decision-frameworks.md`:

1. Establish the architectural requirements first (same list as step 2 above).
2. Compare each named provider's actual capability against those requirements, using
   each provider's own reference file.
3. Identify meaningful differences — operational complexity, security model, scalability
   limits, availability guarantees, cost structure, vendor-specific constraints — not just
   which service has the closest name. Use `references/service-mapping.md` only as an
   orientation aid to find the candidate services, never as proof they're equivalent.
4. Give a recommendation with explicit rationale tied to the stated requirements.

## Validation Workflow

When reviewing an existing architecture (any provider), work through the checklist in
`references/decision-frameworks.md`: assumptions, single points of failure, network
boundaries and traffic flows, IAM and least privilege, private connectivity vs. internet
dependency, HA/DR, observability, scalability and quotas, operational complexity, cost.
Grade findings by severity and give a concrete fix with rationale for each.

## Accuracy

- Never fabricate a price, limit, quota, or SLA figure. Cite it (source + retrieval
  context) or label it an assumption.
- Flag anything likely to be region-restricted, quota-limited, or recently changed, and
  tell the user to verify against current official docs — Microsoft Learn / Azure
  Architecture Center for Azure, AWS Well-Architected / AWS docs for AWS, Google Cloud
  Architecture Framework / Cloud docs for GCP.
- Distinguish an architectural concept (works the same everywhere) from a provider
  implementation detail (works like this *on this provider*) explicitly in your answer.

## References

- [references/azure.md](references/azure.md) — Azure services, identity, networking, WAF
- [references/aws.md](references/aws.md) — AWS services, identity, networking, Well-Architected
- [references/gcp.md](references/gcp.md) — GCP services, identity, networking, Architecture Framework
- [references/service-mapping.md](references/service-mapping.md) — cross-provider orientation table
- [references/architecture-principles.md](references/architecture-principles.md) — neutral principles, styles, antipatterns
- [references/design-patterns.md](references/design-patterns.md) — the 44 cloud design patterns
- [references/security.md](references/security.md) — neutral security model (zero trust, least privilege, secrets)
- [references/decision-frameworks.md](references/decision-frameworks.md) — tech-choice framework, comparison method, review checklist
