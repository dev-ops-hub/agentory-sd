---
name: aws
description: Use for AWS operational work — networking (VPC), IAM policy, managed Kubernetes (EKS), secrets, and cost operations. Not for choosing AWS vs. another provider, which belongs to solution-architect
---

# AWS Operations

## Overview

Operating AWS infrastructure that has already been chosen as the target platform. Provider *selection* (AWS vs. Azure vs. GCP) and system design belong to `solution-architect`'s `multi-cloud-architect` skill — this skill is what to do once AWS is the answer.

## When to Use

- Writing/reviewing Terraform (or other IaC) targeting AWS resources — pairs with `skills/infrastructure/infrastructure-as-code`
- IAM policy design, VPC networking, EKS cluster operations
- AWS-specific secrets, cost, or operational troubleshooting

## IAM

Least-privilege, every time: start from an empty policy and add only the actions a role actually needs, scoped to specific resource ARNs rather than `"Resource": "*"`. Use IAM Roles (assumed via STS, including via OIDC federation from CI — see `skills/cicd/github-actions`) over long-lived IAM User access keys for any workload or pipeline identity; reserve IAM Users for human break-glass access only.

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::app-uploads-prod/*"
}
```

Use `aws iam get-account-authorization-details` + IAM Access Analyzer to find overly-broad existing policies rather than assuming new policies are the only risk.

## VPC Networking

Standard tiered layout: public subnets (NAT gateway, load balancer) and private subnets (application, database) across at least 2 Availability Zones for HA. Private subnets route outbound through a NAT Gateway (per-AZ, to avoid a cross-AZ data-transfer charge and single point of failure) rather than a shared single NAT. VPC endpoints (Gateway for S3/DynamoDB, Interface for other services) avoid routing AWS-internal traffic through a NAT Gateway or the public internet, cutting both cost and exposure.

## EKS (Managed Kubernetes)

EKS manages the control plane; node groups (managed node groups, or Fargate for serverless pods) are the operator's responsibility. IRSA (IAM Roles for Service Accounts) lets a specific Kubernetes ServiceAccount assume a scoped IAM role via OIDC federation — this is the AWS-specific mechanism underlying `skills/security/secrets-and-identity`'s workload-identity pattern; avoid mounting a node-level IAM role's broad permissions to every pod on that node.

## Secrets

AWS Secrets Manager (with automatic rotation for RDS/supported services) or Parameter Store (SecureString, cheaper, no rotation) over environment variables or files for anything a workload needs at runtime — see `skills/security/secrets-and-identity` for the cross-provider pattern.

## Cost Operations

- Tag every resource at creation (`Environment`, `Owner`, `CostCenter`) — untagged resource sprawl is the most common reason cost attribution breaks down later.
- Right-size before reserving: Compute Optimizer / Cost Explorer's rightsizing recommendations before committing to Reserved Instances or Savings Plans, since a mis-sized reservation locks in waste for the term.
- S3 lifecycle policies (transition to Infrequent Access / Glacier, or expire) for data with a known access pattern — unmanaged buckets accumulate storage cost indefinitely.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `"Resource": "*"` in an IAM policy "to get it working" | Scope to specific ARNs; tighten before merging, not after |
| Long-lived IAM User access keys for a CI pipeline or workload | IAM Role via STS/OIDC |
| Shared single NAT Gateway across AZs | Per-AZ NAT Gateway for HA, or VPC endpoints to avoid NAT entirely where applicable |
| Pod-level IAM via the EKS node's instance role | IRSA scoped to the specific ServiceAccount |
| Committing to Reserved Instances before rightsizing | Rightsize first, then reserve |
