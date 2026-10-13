---
name: infrastructure-troubleshooting
description: Use when diagnosing an infrastructure failure — a cluster, pipeline, cloud API, or connectivity problem — before attempting a fix. Specializes systematic-debugging for infrastructure fault domains
---

# Infrastructure Troubleshooting

## Overview

A fault-domain isolation method for infrastructure problems specifically, layered on top of the base `skills/systematic-debugging` discipline (root cause before any fix). This skill is diagnostic, not remediation — it narrows down where a failure lives; the fix itself comes from whichever other skill owns that domain (`skills/containers/kubernetes`, `skills/cloud/<provider>`, etc.).

## When to Use

- A service is unreachable, slow, or failing intermittently and the cause isn't yet known
- A CI pipeline fails inconsistently (not every run)
- A cloud API call is failing or throttled
- Before taking any remediation action during an active, unconfirmed-cause incident

## Fault-Domain Isolation

Work outside-in, confirming each layer before moving to the next, rather than guessing at a cause and trying a fix:

1. **Local**: is the problem specific to one instance/pod/node, or does it affect every instance of the service? (`kubectl get pods -o wide` across replicas, or equivalent) — a single bad instance points at that instance's state, not the system.
2. **DNS**: does the name resolve to what's expected, from where the failure is actually occurring? (Resolution can differ by network context — see split-horizon DNS in `skills/networking/infrastructure-networking`.)
3. **Network/connectivity**: can a connection be established at all (`nc`/`curl` to the resolved address:port) before worrying about what's returned?
4. **Upstream/dependency**: is a dependency (database, external API, another internal service) the actual source, masquerading as this service's failure?
5. **Remote/platform**: is this a provider-side issue (cloud status page, a quota limit, a regional incident) rather than anything in this project's control?

Each layer's answer determines whether to continue inward or stop — if DNS resolves wrong, the problem is DNS/config, not network or application; don't keep debugging deeper layers once an earlier one explains the symptom.

## Intermittent CI Pipeline Failures

Distinguish by pattern before assuming "flaky":

| Pattern | Likely cause |
|---|---|
| Fails only under parallel/matrix jobs | Shared resource contention (a shared test database, a rate-limited external call) |
| Fails only on specific runners | Runner image/cache inconsistency |
| Fails at a consistent step after a consistent duration | A timeout set too tight for occasional real latency, not randomness |
| Fails with different errors each time | Resource exhaustion (OOM, disk) on the runner, not the job's logic |

"Flaky, just retry it" without identifying which of these it is just defers the same failure to a future, less convenient time — treat an intermittent failure as a real bug in the pipeline or its environment until proven otherwise.

## Cloud API Throttling / Rate Limits

A `429`/throttling error is not necessarily a capacity problem — check whether it's a per-second burst limit (needs backoff/retry with jitter, not more capacity) versus a genuine quota ceiling (needs a quota increase request). Exponential backoff with jitter in any automation calling a cloud API is the baseline, not an edge-case addition — a tight retry loop against a rate limit can itself worsen the throttling.

## During an Active Incident

Diagnosis and mitigation are not strictly sequential during a live incident — see `skills/reliability/sre-and-reliability`'s incident-response guidance for when a known mitigation (rollback, failover) should happen *before* root cause is fully understood. This skill's isolation method still applies for narrowing scope quickly, but don't let full root-cause analysis block an available, safe mitigation during active user impact.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Trying a fix before isolating which layer the fault is in | Work outside-in: local → DNS → network → dependency → platform |
| Treating every intermittent CI failure as generic "flakiness" | Classify by pattern first; each pattern has a different real cause |
| Retrying against a rate limit without backoff | Exponential backoff with jitter |
| Full root-cause analysis blocking an available safe mitigation mid-incident | Mitigate first if a known-safe mitigation exists, root-cause after |
