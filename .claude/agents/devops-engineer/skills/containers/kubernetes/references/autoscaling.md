# Autoscaling

## Horizontal Pod Autoscaler (HPA)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app
spec:
  scaleTargetRef: { apiVersion: apps/v1, kind: Deployment, name: app }
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource: { name: cpu, target: { type: Utilization, averageUtilization: 70 } }
```

HPA scales replica count based on observed metrics against resource *requests* (not limits) — a workload with no CPU request set cannot be scaled on CPU utilization at all, since there's no baseline to compute utilization against. This is the most common reason "HPA isn't scaling" turns out to be a missing `resources.requests`.

Custom/external metrics (queue depth, requests-per-second from a service mesh) scale on business-relevant signals rather than CPU, which is often a lagging indicator for I/O-bound workloads — requires the `custom-metrics-apiserver` or a metrics adapter (e.g. KEDA) wired to the actual metric source.

## Vertical Pod Autoscaler (VPA)

Adjusts a pod's resource requests/limits over time based on observed usage, rather than replica count. Running VPA in `Auto` mode alongside HPA on the same metric (CPU) causes the two to fight — VPA changes the request baseline HPA's utilization percentage is computed against. Use VPA in `Off`/recommendation-only mode to size requests correctly, then let HPA handle replica scaling, rather than running both in active mode on the same dimension.

## Cluster Autoscaler

Adds/removes *nodes* when pods are unschedulable due to insufficient capacity (scale up) or nodes are underutilized (scale down). This is the layer below HPA — HPA can request more pods, but if the cluster has no room, the cluster autoscaler must add nodes before those pods actually schedule. A workload with aggressive HPA scaling and a cluster autoscaler with a slow node-provisioning cloud (several minutes to boot a new node) will see a scaling lag — mitigate with slightly higher `minReplicas` as a buffer, or a cluster autoscaler profile tuned for faster scale-up at the cost of some idle headroom.

## Common Mistakes

| Mistake | Fix |
|---|---|
| HPA on CPU with no CPU resource request set | Set `resources.requests.cpu`; HPA utilization is computed against it |
| VPA `Auto` mode + HPA on the same metric | VPA in recommendation-only mode, HPA handles replica scaling |
| Expecting instant pod scheduling when nodes must also scale up | Buffer `minReplicas` or tune cluster-autoscaler scale-up aggressiveness |
