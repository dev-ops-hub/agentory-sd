# Services, Ingress, Networking

## Service Types

| Type | Use when |
|---|---|
| `ClusterIP` (default) | Internal-only communication between workloads |
| `NodePort` | Rarely — direct node-port access, mostly superseded by Ingress/LoadBalancer |
| `LoadBalancer` | Cloud-provisioned external LB, one per Service (expensive if used per-service at scale) |
| `ExternalName` | DNS alias to an external hostname, no proxying |

For many externally-exposed HTTP services, a single Ingress fronting multiple `ClusterIP` Services is far cheaper and more manageable than one `LoadBalancer` Service each.

## Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts: [app.example.com]
      secretName: app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: { name: app, port: { number: 80 } }
```

`cert-manager` with a `ClusterIssuer` automates TLS certificate issuance/renewal from Let's Encrypt or an internal CA — avoid hand-rotated certificates for anything beyond a short-lived demo.

## NetworkPolicy

Default-deny, then explicitly allow required traffic — without any NetworkPolicy, every pod in a cluster can reach every other pod, which is rarely the intent for a multi-tenant or security-sensitive cluster:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-db
spec:
  podSelector: { matchLabels: { app: app } }
  policyTypes: [Egress]
  egress:
    - to: [{ podSelector: { matchLabels: { app: db } } }]
      ports: [{ port: 5432 }]
```

NetworkPolicy enforcement requires a CNI plugin that supports it (Calico, Cilium) — confirm the cluster's CNI before assuming policies take effect.

## Service Mesh (when NetworkPolicy isn't enough)

Istio/Linkerd add mTLS between services, fine-grained traffic routing (canary splits, retries, circuit breakers) and request-level observability — justified when the cluster has enough services that managing per-service traffic/security policy via NetworkPolicy and app-level code becomes unmanageable. Don't adopt a mesh for a handful of services; the operational overhead (sidecar injection, control-plane upgrades) outweighs the benefit until the service count and traffic-policy complexity justify it.

## Common Mistakes

| Mistake | Fix |
|---|---|
| One `LoadBalancer` Service per app at scale | Single Ingress fronting multiple `ClusterIP` Services |
| No NetworkPolicy (every pod reaches every pod) | Default-deny, then explicit allow rules |
| Hand-rotated TLS certificates | cert-manager with an automated issuer |
| Adopting a service mesh for 3 services | Reserve it for a scale where NetworkPolicy + app-level resilience genuinely can't keep up |
