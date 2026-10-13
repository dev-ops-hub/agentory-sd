# Cluster and Workload Upgrades

## Kubernetes Version Upgrades

Upgrade **one minor version at a time** (e.g. 1.28 → 1.29, never 1.28 → 1.30 directly) — the Kubernetes deprecation policy guarantees a removed API has at least one full minor version with a deprecation warning, but skipping versions can skip past that warning window entirely and break on an API that's already gone.

Before upgrading:
1. Check the target version's changelog for removed/deprecated APIs (`kubectl convert`, or `pluto`/`kube-no-trouble` to scan manifests for APIs removed in the target version).
2. Upgrade the control plane first, then node pools (managed Kubernetes services typically enforce this order; self-managed clusters must do it manually).
3. For node pools, prefer a surge/rolling node replacement (new nodes added, old cordoned and drained, then removed) over in-place node upgrades — this is effectively a blue-green at the node level and avoids a window with no capacity.

## Workload API Version Migrations

When a manifest uses an API version slated for removal (e.g. `policy/v1beta1` → `policy/v1` for PodDisruptionBudget), update the manifest's `apiVersion` and re-validate — don't wait until the cluster upgrade that removes the old version to discover a stale manifest, since that turns a routine cluster upgrade into an application-outage incident.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Skipping minor versions on a cluster upgrade | One minor version at a time |
| Upgrading node pools before the control plane | Control plane first, always |
| Discovering a removed API only when the cluster upgrade breaks a workload | Scan manifests for deprecated APIs ahead of each upgrade |
