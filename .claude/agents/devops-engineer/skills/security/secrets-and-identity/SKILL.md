---
name: secrets-and-identity
description: Use when managing secrets infrastructure, workload identity, or certificate infrastructure — Vault, cloud secret managers, mTLS, or least-privilege IAM for a workload
---

# Secrets and Identity

## Overview

Keeping credentials and identity out of code and config, and giving workloads only the access they need. Pairs with the per-cloud-provider identity sections in `skills/cloud/aws`, `skills/cloud/azure`, `skills/cloud/gcp` — this skill is the provider-neutral pattern underneath.

## When to Use

- Setting up a secrets store (Vault, cloud-native secret manager) or deciding where a credential should live
- Configuring workload identity so a pipeline or application doesn't hold a long-lived credential
- Setting up certificate issuance/rotation or mTLS between services
- Reviewing whether a secret is reaching its consumer securely

## The Core Pattern: No Long-Lived Static Credentials

Every cloud provider now offers a workload-identity mechanism (AWS IRSA/OIDC, Azure Managed Identity/Workload Identity, GCP Workload Identity Federation) that lets a workload or CI pipeline assume short-lived, automatically-rotated credentials tied to its actual identity (a Kubernetes ServiceAccount, a CI job's OIDC token) rather than a downloaded, manually-rotated key. Default to this for any new integration; treat a stored static credential (access key, service-account JSON, client secret) as something that needs a specific justification, not the default.

## Secrets Stores

| Store | Fits when |
|---|---|
| HashiCorp Vault | Multi-cloud, needs dynamic secrets (short-lived DB credentials generated per-request), or secrets-as-a-service across many consumers |
| Cloud-native (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) | Single-cloud, wants native IAM integration with no extra infrastructure to run |

Either way: the secret's *value* should never pass through a CI log, a Kubernetes Secret object committed to Git, or an environment variable visible via `/proc` to any process on a shared host — fetch it at runtime via the workload's identity, scoped to only the secrets that workload needs (a path-based or role-based policy, not "this app can read every secret in the store").

## Secrets in Kubernetes

A raw Kubernetes `Secret` is base64-encoded, not encrypted, unless the cluster has encryption-at-rest enabled for the Secrets resource — and even then, anyone with `get secret` RBAC in that namespace can read it in plaintext. Prefer the External Secrets Operator or a provider's CSI secrets-store driver to sync from Vault/a cloud secret manager into a Secret at deploy time (or mount directly, bypassing the Secret object entirely), so the actual secret value's source of truth and audit trail live in the secrets store, not in `kubectl get secret -o yaml`.

## Rotation

A secret that's never rotated is a secret that, once leaked, stays leaked indefinitely. Automatic rotation (supported natively for many database/cloud-service credentials) is strictly better than manual; where only manual rotation is possible, a defined rotation schedule with an owner is still better than "rotate when we remember" (which in practice means "rotate after an incident").

## Certificate Infrastructure

Automate issuance and renewal (cert-manager + an ACME issuer like Let's Encrypt, or an internal CA for service-to-service certs) rather than manually tracked expiry — see `skills/networking/infrastructure-networking`'s TLS section. For service-to-service mTLS at scale, a service mesh's automatic certificate rotation (short-lived certs, rotated continuously) removes the operational burden of a long-lived cert's renewal process entirely.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Downloaded static credential (access key, SA JSON) for a workload identity need | Workload-identity federation (IRSA/Managed Identity/Workload Identity Federation) |
| Secret value visible in a CI log or committed Kubernetes Secret manifest | Fetch at runtime via workload identity; never commit a secret value |
| Broad store-wide read access instead of per-secret/path scoping | Scope policy to only the secrets a given workload actually needs |
| No rotation schedule, or rotation only after an incident | Automatic rotation where supported; a scheduled owner otherwise |
| Manually tracked certificate expiry | Automated issuance/renewal |
