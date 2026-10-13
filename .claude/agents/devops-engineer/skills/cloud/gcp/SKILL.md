---
name: gcp
description: Use for GCP operational work — VPC networking, IAM, managed Kubernetes (GKE), Secret Manager, and cost operations. Not for choosing GCP vs. another provider, which belongs to solution-architect
---

# GCP Operations

## Overview

Operating GCP infrastructure that has already been chosen as the target platform. Provider *selection* belongs to `solution-architect`'s `multi-cloud-architect` skill — this skill is what to do once GCP is the answer.

## When to Use

- Writing/reviewing Terraform targeting GCP resources — pairs with `skills/infrastructure/infrastructure-as-code`
- IAM role/binding design, VPC networking, GKE cluster operations
- GCP-specific secrets, cost, or operational troubleshooting

## IAM

Predefined roles over `roles/owner`/`roles/editor` for anything beyond a sandbox project — a service account bound `roles/editor` on a production project is the GCP equivalent of a wildcard IAM policy. Bind roles at the narrowest resource hierarchy level (project > folder > organization, prefer project or lower) that satisfies the need. Workload Identity Federation lets an external identity (a CI pipeline, another cloud) assume a GCP service account's permissions without a downloaded service-account JSON key — strongly prefer it over long-lived SA keys, which have no expiry by default and are a common leak vector.

```bash
gcloud iam service-accounts add-iam-policy-binding \
  app-sa@project.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:project.svc.id.goog[namespace/ksa-name]"
```

## VPC Networking

GCP VPCs are global (subnets are regional, not zonal) — a single VPC can span regions without peering, unlike AWS/Azure's region-scoped VNets/VPCs. Shared VPC (host project + service projects) centralizes network administration across teams/projects while letting each team manage its own resources within the shared network. Private Google Access and Private Service Connect avoid routing traffic to Google APIs or peered services over the public internet.

## GKE (Managed Kubernetes)

Workload Identity (GKE's binding of a Kubernetes ServiceAccount to a GCP service account) is the GCP analogue of AWS IRSA / Azure Workload Identity — same reasoning: scope permissions to the workload, not the node pool. Prefer GKE Autopilot for new clusters unless the workload has node-level customization needs Autopilot doesn't support (Autopilot removes node management entirely, including most of the node-pool-level security hardening concerns that apply to Standard clusters). Private clusters (no public control-plane or node IP) plus Binary Authorization to require image signing/attestation (ties into `skills/cicd/supply-chain-security`) before a workload can run.

## Secrets

Secret Manager, accessed via Workload Identity, with automatic rotation for supported integrations — never a plaintext value in a ConfigMap, environment variable baked into an image, or Terraform state in plain form (state encryption still matters, per `skills/infrastructure/infrastructure-as-code`).

## Cost Operations

- Labels (GCP's term for tags) at creation, enforced via an Organization Policy constraint requiring them.
- Committed Use Discounts after rightsizing via Recommender's rightsizing insights, not before.
- BigQuery billing export + a budget alert (not just the console's cost view) for proactive cost anomaly detection rather than discovering overspend at month-end.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `roles/editor` bound to a service account on a prod project | Predefined, narrowly-scoped roles |
| Long-lived downloaded service-account JSON keys | Workload Identity Federation |
| Treating VPCs as region-scoped like AWS/Azure | Remember GCP VPCs are global; subnets are regional |
| Plaintext secret in a ConfigMap or baked into an image | Secret Manager via Workload Identity |
| Committing to CUDs before rightsizing | Rightsize via Recommender first |
