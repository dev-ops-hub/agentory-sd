---
name: kubernetes
description: Use when writing or reviewing Kubernetes manifests or Helm charts, configuring ingress/autoscaling/RBAC, planning a cluster upgrade, or debugging a workload that won't schedule or can't reach a dependency
---

# Kubernetes

## Overview

Operating Kubernetes workloads and clusters: what a correct manifest looks like, how traffic and scaling work, how access is controlled, and how to approach an unhealthy cluster. Deep topics live in `references/` — load only the one the task needs.

## When to Use

- Writing or reviewing a Deployment/Service/ConfigMap/Secret/manifest or Helm chart
- Configuring ingress, TLS, or autoscaling for a workload
- Setting up or reviewing RBAC/NetworkPolicy
- A pod won't schedule, crashes on start, or can't reach another service
- Planning a cluster or workload version upgrade

## Core Workload Shape

A production Deployment names its resource requests/limits, a liveness and readiness probe, and never runs as a singleton it can't afford to lose:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 3
  selector:
    matchLabels: { app: app }
  template:
    metadata:
      labels: { app: app }
    spec:
      securityContext:
        runAsNonRoot: true
        seccompProfile: { type: RuntimeDefault }
      containers:
        - name: app
          image: registry.example.com/app:sha-abc123
          resources:
            requests: { cpu: "250m", memory: "256Mi" }
            limits: { memory: "512Mi" }   # no CPU limit: throttling CPU causes latency spikes CPU requests alone don't
          readinessProbe:
            httpGet: { path: /ready, port: 8080 }
            initialDelaySeconds: 5
          livenessProbe:
            httpGet: { path: /health, port: 8080 }
            initialDelaySeconds: 15
```

**Requests vs. limits**: requests drive scheduling (the scheduler won't place a pod where its requested resources don't fit) — set them to real steady-state usage, not a guess. Memory limits are a hard OOM-kill boundary; CPU limits cause throttling, not death, but throttling under a limit set too tight manifests as latency spikes that look like an unrelated bug — many teams set memory limits but omit CPU limits for this reason, relying on requests + the node's own capacity for CPU fairness.

**Readiness vs. liveness**: readiness controls whether the pod receives traffic (fails during startup, a dependency outage, or graceful shutdown without killing the pod); liveness controls whether Kubernetes restarts the container. A liveness probe hitting a dependency it doesn't actually need to be alive (e.g. checking a downstream API) causes restart storms when that downstream has a blip — liveness should check only "is this process itself stuck," readiness checks "can this pod currently serve traffic."

## Config and Secrets

ConfigMaps for non-sensitive config, Secrets for sensitive values — but a raw Kubernetes Secret is only base64-encoded, not encrypted at rest by default (depends on cluster configuration: enable encryption at rest, or better, don't put raw secret values in the cluster at all). See `skills/security/secrets-and-identity` for external-secrets-operator / cloud-secret-manager integration patterns that keep the actual secret value out of etcd.

## References

- `references/networking-ingress.md` — Services, Ingress, TLS termination, NetworkPolicy
- `references/helm.md` — chart structure, templating, values layering per environment
- `references/autoscaling.md` — HPA, VPA, cluster autoscaler, and the requests/limits interaction with each
- `references/rbac-security.md` — RBAC, Pod Security Standards, admission control
- `references/troubleshooting.md` — pod won't schedule / CrashLoopBackOff / can't reach a service, by symptom
- `references/upgrades.md` — cluster and workload API-version upgrade strategy

## Common Mistakes

| Mistake | Fix |
|---|---|
| No resource requests/limits | Set both; let OOM-kill be a deliberate boundary, not an accident |
| Liveness probe checking a downstream dependency | Liveness checks only this process; readiness checks dependencies |
| `replicas: 1` for anything expected to stay up during a deploy | At least 2-3 replicas with a PodDisruptionBudget |
| Secrets committed as plain YAML manifests in Git | External secret store + operator, or sealed-secrets; never a plaintext Secret manifest in version control |
| `kubectl apply` run by hand against prod | GitOps reconciliation (Argo CD/Flux) so cluster state matches a Git-tracked source of truth |
