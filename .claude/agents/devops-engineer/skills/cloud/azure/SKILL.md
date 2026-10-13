---
name: azure
description: Use for Azure operational work — VNet networking, Azure AD/Entra ID roles, managed Kubernetes (AKS), Key Vault, and cost management. Not for choosing Azure vs. another provider, which belongs to solution-architect
---

# Azure Operations

## Overview

Operating Azure infrastructure that has already been chosen as the target platform. Provider *selection* belongs to `solution-architect`'s `multi-cloud-architect` skill — this skill is what to do once Azure is the answer.

## When to Use

- Writing/reviewing Bicep or Terraform targeting Azure resources — pairs with `skills/infrastructure/infrastructure-as-code`
- Entra ID (Azure AD) role design, VNet networking, AKS operations
- Azure-specific secrets, cost, or operational troubleshooting

## Identity (Entra ID / RBAC)

Azure RBAC roles scoped at the narrowest level that works (resource > resource group > subscription > management group) — a role assignment at subscription scope for something that only needs one resource group's access is the Azure equivalent of an overbroad IAM policy. Use Managed Identities (system- or user-assigned) for any Azure resource or workload needing to call another Azure service, rather than a service principal with a stored client secret — a Managed Identity has no credential to leak or rotate.

```bash
az role assignment create \
  --assignee <managed-identity-principal-id> \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/.../resourceGroups/rg-prod/providers/Microsoft.Storage/storageAccounts/appstorage
```

## VNet Networking

Hub-and-spoke topology for multi-subscription/multi-team estates: a hub VNet holds shared services (firewall, VPN/ExpressRoute gateway, DNS), spoke VNets hold workloads, peered to the hub (not to each other, routed through the hub's firewall/NVA for inter-spoke traffic that needs inspection). Network Security Groups (NSGs) at the subnet level, with Application Security Groups to group VMs/resources logically rather than hardcoding IP ranges in NSG rules.

## AKS (Managed Kubernetes)

Workload Identity (the current, OIDC-federation-based mechanism — supersedes the deprecated AAD Pod Identity) lets a Kubernetes ServiceAccount map to an Entra ID identity, the Azure analogue of AWS IRSA — same reasoning: don't grant broad permissions at the node pool's identity and inherit them to every pod. Private clusters (API server not publicly reachable) plus Azure Policy for AKS (the Azure-native layer equivalent to the Kyverno/OPA patterns in `skills/security/infrastructure-hardening`) for cluster-wide guardrails.

## Secrets

Azure Key Vault for secrets, keys and certificates, accessed via Managed Identity (not a stored access key) and, for AKS workloads, the Secrets Store CSI Driver to mount Key Vault secrets directly into pods without them ever living in a Kubernetes Secret object — see `skills/security/secrets-and-identity` for the cross-provider pattern.

## Cost Management

- Tag resources (`Environment`, `Owner`, `CostCenter`) at creation via Azure Policy enforcement, not convention alone — Azure Policy can require tags and block untagged resource creation.
- Azure Advisor's cost recommendations before committing to Reserved Instances/Savings Plans.
- Resource groups scoped to a lifecycle (one environment, one deletable unit) make cost attribution and cleanup far simpler than resources scattered across shared groups.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Role assignment at subscription scope for a single-resource-group need | Scope to the resource group or resource |
| Service principal with a stored client secret for workload identity | Managed Identity (system- or user-assigned) |
| Spoke-to-spoke VNet peering bypassing the hub firewall | Route inter-spoke traffic through the hub for inspection |
| Secrets as plain Kubernetes Secret objects on AKS | Secrets Store CSI Driver backed by Key Vault |
| Resources scattered across shared resource groups by convenience | One resource group per lifecycle/environment |
