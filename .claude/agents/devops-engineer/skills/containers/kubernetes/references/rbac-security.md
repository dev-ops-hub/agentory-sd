# RBAC, Pod Security, Admission Control

## RBAC

Grant the narrowest Role that lets a workload or user do its job — a `ClusterRole` with `*`/`*`/`*` handed to a CI service account because "it was easier" is the single most common Kubernetes privilege-escalation path:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { namespace: staging, name: deployer }
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { namespace: staging, name: ci-deployer }
subjects:
  - kind: ServiceAccount
    name: ci-deploy
    namespace: staging
roleRef: { kind: Role, name: deployer, apiGroup: rbac.authorization.k8s.io }
```

Namespaced `Role`/`RoleBinding` over cluster-wide `ClusterRole`/`ClusterRoleBinding` whenever the access genuinely only needs one namespace — a GitOps deploy pipeline for a single service should not hold a cluster-admin binding "just in case."

## Pod Security Standards

Enforced per-namespace via the built-in Pod Security Admission controller (replaced the deprecated PodSecurityPolicy):

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/warn: restricted
```

`restricted` requires `runAsNonRoot`, drops all capabilities by default, and forbids privilege escalation — the baseline every production namespace should enforce unless a specific workload has a documented reason to run privileged (rare, and itself a signal to re-examine the workload).

## Admission Control (Policy-as-Code)

OPA Gatekeeper or Kyverno enforce cluster-wide policy beyond what Pod Security Standards cover — no `:latest` tags, required resource limits, no public LoadBalancer without an allowlist annotation:

```yaml
# Kyverno example: require resource limits on every container
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata: { name: require-limits }
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-limits
      match: { resources: { kinds: [Pod] } }
      validate:
        message: "every container must set resource limits"
        pattern:
          spec:
            containers:
              - resources: { limits: { memory: "?*" } }
```

Start new policies in `Audit`/`validationFailureAction: Audit` mode to see what would be blocked before switching to `Enforce` — flipping straight to enforce on an existing cluster can break workloads that were never compliant and are now mid-deploy.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `ClusterRole` with wildcard verbs/resources for a single-namespace workload | Namespaced `Role` scoped to actual needed verbs/resources |
| No Pod Security Standard set on a namespace | Set `restricted` (or `baseline` with a documented reason) on every production namespace |
| New admission policy deployed straight to `Enforce` | Start in `Audit`, confirm no unexpected blocks, then switch |
