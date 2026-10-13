# Provider-Neutral Security Model

Security concepts that apply the same way regardless of provider. For the service that
implements each concept (identity platform, secrets store, key management, WAF, DDoS
protection), see the provider's reference file — the mechanisms differ enough between
providers that mapping by name alone is a common and dangerous mistake (see "Do Not
Assume" in SKILL.md).

---

## Zero Trust Principles

1. **Verify explicitly** — authenticate and authorize based on every available signal
   (identity, device, location, service health), not network location alone.
2. **Use least-privilege access** — scope access to exactly what's needed, prefer
   just-in-time and just-enough-access over standing broad grants.
3. **Assume breach** — segment access to minimize blast radius, verify encryption
   end-to-end, instrument for anomaly detection rather than assuming the perimeter holds.

## Identity: The Core Design Decision

Centralize identity instead of building or managing your own authentication/authorization
system. Beyond that shared principle, the three providers diverge structurally:

- A workload calling another service on the **same** provider should authenticate via
  that provider's native workload-identity mechanism (not a static credential) —
  see each provider's reference for the specific mechanism (managed identity / IAM
  role / service account + federation).
- A workload calling **across** providers, or a CI/CD pipeline running outside any of
  them, should use federated identity (OIDC token exchange) rather than a long-lived key
  — again, provider-specific setup, same underlying idea.
- Never store credentials in application code or configuration. If a static credential
  genuinely can't be avoided, treat it as a last resort: rotate frequently, scope
  narrowly, and track an explicit plan to eliminate it.
- Adopt modern authentication for human users: passwordless (FIDO2/WebAuthn), conditional
  access policies, MFA, SSO via federation protocols (SAML, OIDC, OAuth 2.0).

## Secrets and Key Management

- Secrets (API keys, DB passwords, signing keys, OAuth client secrets) belong in the
  provider's managed secrets service, never in env vars baked into an image, a config
  file in source control, or a database column.
- Encryption keys belong in the provider's managed key-management service. Use
  customer-managed keys when compliance requires control over key lifecycle; otherwise
  provider-managed default encryption is appropriate.
- Rotate secrets and keys on a defined schedule, automated where the provider supports
  it, and audit every access.
- Scope access to a secret at the secret level, not just the project/account level.

## Network Security

- Prefer private connectivity (private endpoints / private service connectivity) for
  access to managed services over public-internet access, even when that access is
  authenticated — public exposure is an additional attack surface regardless of auth.
- Segment networks so a compromise in one segment doesn't grant lateral access to
  everything else; default-deny, allow explicitly.
- Put a WAF and DDoS protection in front of any public-facing HTTP(S) endpoint.
- Enforce TLS 1.2+ everywhere; terminate TLS at a point you control and re-encrypt
  internally for sensitive paths rather than assuming internal networks are trusted.

## Defense in Depth — Layered Controls

| Layer | Control |
|---|---|
| Edge | DDoS protection, WAF, rate limiting |
| Identity | Workload identity (no static keys), RBAC/least-privilege roles, MFA for humans |
| Network | Private endpoints/connectivity, network segmentation, default-deny |
| Data | Encryption at rest and in transit, customer-managed keys where required |
| Supply chain | Scan and gate external artifacts (container images, packages, IaC modules) before use — see the Quarantine pattern in `design-patterns.md` |
| Operations | Privileged access management, time-bound elevated access, audit logging exported somewhere durable and queryable |

## Common Findings (apply on any provider)

- **Public exposure of a managed data service** (database, cache, object store) that
  should be private-only — the single most common and most severe finding.
- **Long-lived static credentials** (keys, passwords) committed to source or baked into
  images, where a federated/workload-identity alternative exists.
- **Overly broad IAM grants** — basic/owner-equivalent roles bound at a scope wider than
  necessary, instead of a narrowly-scoped predefined or custom role at resource level.
- **No audit log export** — logs exist but aren't exported anywhere durable/queryable,
  so a breach can't be reconstructed after the fact.
- **Missing encryption or weak TLS** on a path assumed to be "internal only."

## Supply-Chain and Artifact Trust

External artifacts — container images, packages, IaC modules, data files — need
validation before use: scan for known vulnerabilities, gate promotion through quality
tiers (untested → tested → approved), and keep traceability for exactly which version is
deployed where. See the Quarantine and Gatekeeper patterns in `design-patterns.md`.

---

> Generalized from the Azure Architecture Center's identity and mission-critical security
> guidance. Provider-specific services (Entra ID, Key Vault, IAM, Secrets Manager, Cloud
> IAM, Secret Manager, etc.) are documented in each provider's reference file, not here.
