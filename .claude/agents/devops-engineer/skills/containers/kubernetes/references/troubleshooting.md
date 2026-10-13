# Kubernetes Troubleshooting by Symptom

Pairs with `skills/systematic-debugging` (root cause before any fix) and `skills/troubleshooting/infrastructure-troubleshooting` (fault-domain isolation). This file is the Kubernetes-specific symptom map.

## Pod Won't Schedule (`Pending`)

```bash
kubectl describe pod <pod> -n <ns>   # read the Events section
```

| Event message | Cause |
|---|---|
| `Insufficient cpu`/`memory` | No node has enough free capacity for the pod's requests — check cluster autoscaler status, or the requests are oversized |
| `node(s) had taint {...} that the pod didn't tolerate` | Pod needs a toleration for a tainted node pool (e.g. GPU nodes), or should target a different pool |
| `0/N nodes are available: N node(s) didn't match node affinity` | `nodeSelector`/`affinity` rule doesn't match any node's labels |
| `persistentvolumeclaim ... not found/pending` | PVC unbound — check StorageClass exists and the provisioner is healthy |

## CrashLoopBackOff

```bash
kubectl logs <pod> -n <ns> --previous   # the crashed instance's logs, not the new restart
```

Check the *previous* container's logs, not the current one — a container in `CrashLoopBackOff` has already restarted, so `kubectl logs` without `--previous` may show nothing or logs from a different crash. Common causes: unhandled startup exception (check logs), liveness probe failing before the app finishes initializing (check `initialDelaySeconds`), or `OOMKilled` (check `kubectl describe pod` for `Reason: OOMKilled` and raise the memory limit or fix a leak).

## Service Unreachable From Another Pod

Isolate by layer, outside-in:

1. `kubectl exec` into the calling pod, `nslookup <service>.<namespace>.svc.cluster.local` — DNS resolution failing points at CoreDNS or a namespace/name typo, not the target service.
2. If DNS resolves, `curl`/`nc` the resolved ClusterIP:port from the calling pod — connection refused means the target isn't listening on that port (check the Service's `targetPort` matches the container's actual listening port, a frequent mismatch); timeout suggests a NetworkPolicy is blocking it.
3. Check NetworkPolicies in both the caller's and target's namespace for a default-deny with no matching allow rule.
4. If a service mesh is present, check sidecar injection actually happened on both pods (`kubectl get pod -o jsonpath='{.spec.containers[*].name}'`) — a pod missing its sidecar in a mesh enforcing mTLS gets connection resets that look like a NetworkPolicy issue.

## Cluster/Node-Level Issues

- `kubectl get nodes` showing `NotReady` — check `kubectl describe node <node>` for kubelet/network-plugin conditions before assuming it's an application problem.
- Many pods `Pending` cluster-wide — check cluster autoscaler logs/status; it may be hitting a cloud-provider quota limit on instance count, not a Kubernetes-side misconfiguration.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Reading current-container logs on a `CrashLoopBackOff` pod | Use `--previous` to see the actual crash |
| Assuming connectivity failures are app bugs before checking NetworkPolicy/DNS | Isolate by layer: DNS → connect → NetworkPolicy → mesh sidecar |
| Restarting/deleting a pod before reading `describe`'s Events | Always read Events first — it usually names the exact scheduling/startup cause |
