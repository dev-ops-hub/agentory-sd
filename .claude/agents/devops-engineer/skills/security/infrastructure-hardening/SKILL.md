---
name: infrastructure-hardening
description: Use when hardening a container, cluster, or network against infrastructure-level attack surface — CIS benchmarks, Kubernetes/container hardening, network security, or policy-as-code enforcement
---

# Infrastructure Hardening

## Overview

Reducing infrastructure-level attack surface: the platform and configuration, not application code (that's `software-engineer`'s `application-security`). Complements `skills/containers/kubernetes/references/rbac-security.md` (which covers the Kubernetes-native mechanisms) with the broader hardening and policy-enforcement picture.

## When to Use

- Hardening a host, container, or cluster baseline
- Setting up or extending policy-as-code enforcement (OPA/Gatekeeper, Kyverno, Checkov)
- Reviewing infrastructure configuration against a CIS benchmark or similar standard
- Network-layer hardening beyond basic firewall rules (see `skills/networking/infrastructure-networking` for the base layer)

## CIS Benchmarks

CIS publishes hardening benchmarks per platform (Linux distributions, Kubernetes, Docker, each major cloud). Treat a benchmark as a prioritized checklist, not a single pass/fail gate — many controls trade a hardening gain for an operational cost (disabling a kernel module that a legitimate workload needs), so apply controls that fit the actual threat model and document any skipped control with the reason, rather than blindly scripting every item.

```bash
# kube-bench runs the CIS Kubernetes Benchmark against a live cluster
kube-bench run --targets master,node
```

## Container and Kubernetes Hardening

Beyond the per-workload Pod Security Standards covered in `skills/containers/kubernetes/references/rbac-security.md`: node-level hardening (minimal host OS, no unnecessary host-level daemons, kubelet API locked down), image hardening (minimal/distroless base images, no shell in production images where feasible — see `skills/containers/docker`), and runtime hardening (seccomp/AppArmor profiles beyond the Kubernetes default, read-only root filesystem where the workload allows it).

```yaml
securityContext:
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities: { drop: ["ALL"] }
```

A container that genuinely needs to write locally (a cache directory, a temp file) still works with `readOnlyRootFilesystem: true` by mounting an `emptyDir` volume at exactly that path — the goal is minimizing writable surface, not breaking the workload.

## Policy as Code

Enforce infrastructure-wide invariants automatically rather than relying on manual review catching every violation:

```rego
# OPA/Rego: deny S3 buckets without encryption
deny[msg] {
  input.resource_type == "aws_s3_bucket"
  not input.config.server_side_encryption_configuration
  msg := "S3 buckets must have encryption enabled"
}
```

Run policy checks at the point they're cheapest to fix: `checkov`/`tfsec`/`conftest` against Terraform plans in CI (before `apply`), Kyverno/Gatekeeper admission control against the live cluster (before a resource is created, not after). Both layers matter — CI-time catches it before it's provisioned at all; admission control catches anything that bypasses CI (a manual `kubectl apply`, a different pipeline). Start new policies in audit/dry-run mode, confirm the expected set of violations, then switch to enforcing — the same rollout discipline as `skills/containers/kubernetes/references/rbac-security.md`'s admission-control guidance.

## Network Security (Hardening Layer)

Beyond `skills/networking/infrastructure-networking`'s baseline default-deny posture: a WAF in front of internet-facing HTTP services for common attack-pattern filtering (not a substitute for secure application code, a complementary layer), DDoS protection at the edge for anything public-facing with real exposure, and periodic review of security-group/NSG/firewall rules for drift — rules accumulate over time as "temporarily" opened and never closed.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Scripting every CIS control blindly, breaking a legitimate workload | Prioritize by actual threat model; document skipped controls with reason |
| No `readOnlyRootFilesystem`, assuming it breaks the workload | Mount an `emptyDir` for the specific writable path the workload needs |
| Policy-as-code enforced immediately with no audit period | Audit/dry-run first, then switch to enforce |
| Relying on CI-time policy checks alone | Also enforce at admission control for anything that bypasses CI |
| Firewall rules opened "temporarily" and never revisited | Periodic rule review as a scheduled practice |
