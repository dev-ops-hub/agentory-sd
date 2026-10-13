---
name: sre-and-reliability
description: Use when defining SLIs/SLOs, responding to an incident, writing a runbook or postmortem, or planning disaster recovery, backup, or capacity
---

# SRE and Reliability

## Overview

Reliability engineering practice: defining what "reliable enough" means for a service, responding when it isn't, and learning from the gap. Not application-level resilience code (retries, circuit breakers in app logic) — that's software-engineer's `integration-patterns`; this is the operational and process layer around it.

## When to Use

- Defining an SLI/SLO for a service, or setting up SLO-based alerting
- An active incident, or writing a runbook ahead of one
- Writing a postmortem after an incident resolves
- Planning disaster recovery, backup strategy, or capacity

## SLI / SLO / Error Budget

An **SLI** is a measured indicator (request success rate, p99 latency). An **SLO** is a target for that indicator over a window (99.9% of requests succeed over 28 days). The **error budget** is `1 - SLO` — the amount of unreliability the service is allowed to spend before it's considered to be missing its target. An SLO with no error budget policy (what happens when the budget is spent — freeze risky deploys, prioritize reliability work over features) is just a number on a dashboard with no operational teeth.

Pick SLIs that reflect actual user experience, not what's easiest to measure — a server-side success-rate SLI that excludes client-side timeout failures looks better than the service actually is.

## SLO-Based Alerting (Multi-Window Burn-Rate)

Alert on the *rate* of error-budget consumption, not a single-window threshold crossing, to balance speed against noise:

```yaml
# Fast burn: page immediately — budget exhausted in hours at this rate
- alert: ErrorBudgetBurnFast
  expr: (sum(rate(http_requests_total{status=~"5.."}[1h])) / sum(rate(http_requests_total[1h]))) > (14.4 * 0.001)
  for: 2m
  labels: { severity: page }

# Slow burn: ticket, not a page — budget exhausted in days at this rate
- alert: ErrorBudgetBurnSlow
  expr: (sum(rate(http_requests_total{status=~"5.."}[6h])) / sum(rate(http_requests_total[6h]))) > (6 * 0.001)
  for: 15m
  labels: { severity: ticket }
```

A short window alone is noisy (pages on brief blips); a long window alone is slow to detect real outages. Running both catches a fast catastrophic failure quickly and a slow, sustained degradation without paging on noise.

## Incident Response

**First 5 minutes**: assess severity (user-visible impact, scope, data-integrity risk), declare an incident if warranted, assign an incident commander, open a communication channel. Severity classification (SEV1 full outage, SEV2 major degradation, SEV3 minor/workaround-available) determines escalation and communication cadence — define the levels before an incident, not during one.

**During**: the incident commander coordinates, doesn't necessarily investigate directly; one communication channel, timestamped updates, mitigate before root-causing if a known mitigation exists (roll back, fail over, scale up) — restoring service comes before full understanding.

**Blameless by design**: a postmortem process that assigns individual blame teaches people to hide information next time, which is strictly worse for the system's actual reliability than any individual mistake.

## Runbooks

A runbook for a known failure mode names: detection (how you'd know this is happening), triage steps (confirm it's actually this failure, not something else presenting similarly), mitigation (the fastest safe path to restoring service), and escalation (who/what to involve if mitigation doesn't work). Write runbooks for failure modes that have happened before or are foreseeable from the architecture — a runbook for every hypothetical failure dilutes attention from the ones that actually recur.

## Postmortems

Structure: timeline (what happened, when, including detection and response), impact (who/what was affected, how badly, for how long), root cause (the systemic reason, not "someone made a mistake" — go past the human action to why the system allowed it), and action items (concrete, owned, with a mechanism preventing recurrence — not just "be more careful"). A postmortem with no action item that would have prevented or caught the issue faster didn't do its job.

## Disaster Recovery / Backup

Define **RPO** (Recovery Point Objective: how much data loss is acceptable, drives backup frequency) and **RTO** (Recovery Time Objective: how long recovery may take, drives the DR architecture — backup-and-restore vs. a warm/hot standby). An untested backup is a hypothesis, not a recovery plan — restore drills on a schedule, not only when a real incident forces the first attempt.

## Capacity Planning

Forecast from actual growth trends and known upcoming events (a launch, a seasonal spike), not a flat percentage buffer on current usage — and verify headroom against the slowest-to-scale dimension (a database that can't horizontally scale, a cloud quota that requires a support ticket to raise) rather than just the easiest one (stateless compute, which usually autoscales fine).

## Common Mistakes

| Mistake | Fix |
|---|---|
| SLO defined with no error budget policy | Define what happens when the budget is spent |
| Single-window alert threshold | Multi-window burn-rate alerting |
| Postmortem blaming an individual action | Root-cause the systemic reason the system allowed it |
| Backups never restore-tested | Scheduled restore drills |
| Capacity planned only against the easiest-to-scale dimension | Check the slowest-to-scale constraint too |
