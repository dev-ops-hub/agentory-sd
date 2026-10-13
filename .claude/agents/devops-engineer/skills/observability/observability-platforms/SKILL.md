---
name: observability-platforms
description: Use when setting up or operating metrics, logging, or tracing infrastructure — Prometheus/Grafana/OpenTelemetry, log collection, alerting rules, or dashboards. Not for adding instrumentation code to an application, which belongs to software-engineer
---

# Observability Platforms

## Overview

Operating the infrastructure that collects, stores, and surfaces metrics, logs and traces — not the application code that emits them. Software-engineer decides *what* an app measures/logs and adds the instrumentation calls; this skill is where that data goes and how it's queried, alerted on and displayed.

## When to Use

- Setting up Prometheus scraping, Grafana dashboards, or an OpenTelemetry Collector pipeline
- Configuring log collection/aggregation infrastructure
- Writing or reviewing alerting rules
- Deciding retention policy for metrics/logs/traces

## The Three Pillars, and Where Each Lives

| Pillar | Platform concern (yours) | App concern (software-engineer's) |
|---|---|---|
| Metrics | Scrape config, storage, recording rules, dashboards, alerting | Which metrics to emit, cardinality discipline in label choices |
| Logs | Collection agent, aggregation/storage, retention, log-based alerting | Structured log format, log levels, what to log |
| Traces | Collector pipeline, storage/sampling backend, trace-based alerting | Span creation, context propagation across service calls |

## Metrics (Prometheus)

```yaml
scrape_configs:
  - job_name: 'app'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
```

Annotation-based scrape discovery (`prometheus.io/scrape: "true"`) over a static, manually-maintained target list — a hardcoded list drifts the moment anyone adds a service and forgets to update it.

**Cardinality** is the main Prometheus operational risk: a label with high-cardinality values (user ID, raw URL path with IDs embedded) multiplies the number of time series and can take down a Prometheus instance's memory. If an app's instrumentation is already emitting unbounded-cardinality labels, that's a software-engineer-owned fix (bucket/normalize the label), not something a platform-side recording rule can repair.

**Recording rules** pre-aggregate expensive queries that dashboards/alerts hit repeatedly, trading storage for query latency — write one when a PromQL query used in multiple dashboards/alerts takes a visible fraction of a second to evaluate.

## Dashboards (Grafana)

Provision dashboards as code (JSON/Jsonnet checked into version control, loaded via a provisioning config or the Grafana API) rather than hand-built-and-exported — a hand-built dashboard that only exists in the Grafana UI has no history, no review, and is one accidental edit away from being wrong with no way to diff what changed.

Design each dashboard around one of two shapes: a RED dashboard (Rate, Errors, Duration — per-service, request-driven workloads) or a USE dashboard (Utilization, Saturation, Errors — per-resource, infrastructure-driven). Mixing both shapes on one dashboard usually produces a wall of panels nobody reads during an incident.

## Logging Infrastructure

A collection agent (Fluent Bit/Fluentd, or the cloud-native equivalent) ships structured logs to an aggregation backend (ELK, Loki, or a managed log service) — the agent's job is reliable shipping with backpressure handling, not transformation; keep transformation logic (parsing, enrichment) either in the app's own structured-log emission or in a well-tested pipeline stage, not scattered across ad hoc agent-config regex.

Retention is a cost/compliance tradeoff, not a default to leave unset: hot storage (fast query, short retention) for recent operational logs, cold/archive storage for compliance-driven longer retention, with an explicit deletion policy for anything containing data subject to a retention limit.

## Tracing (OpenTelemetry)

The OpenTelemetry Collector decouples app instrumentation from the backend (Jaeger, Tempo, a vendor APM) — point apps at the Collector, and change backends by reconfiguring the Collector's exporters, not by re-instrumenting every app. Tail-based sampling (decide what to keep after seeing the full trace, e.g. keep all error traces + a percentage of successful ones) gets useful signal at a fraction of head-based sampling's storage cost, at the cost of needing to buffer complete traces before the sampling decision.

## Alerting

Alert on symptoms (user-visible impact: error rate, latency, saturation) rather than causes (a specific internal metric crossing a threshold with no clear link to impact) — a cause-based alert fires on things that don't matter and gets muted; a symptom-based alert maps directly to "should someone be paged right now." See `skills/reliability/sre-and-reliability` for SLO-based alerting (multi-window burn-rate alerts), which is the maturest version of this principle.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Static scrape target list | Annotation/service-discovery-based scraping |
| Unbounded-cardinality labels (user ID, raw path) crashing Prometheus | Flag to software-engineer for bucketing/normalization at the instrumentation layer |
| Hand-built, UI-only dashboards | Dashboards as code, version-controlled |
| Cause-based alerts with no clear user impact | Symptom-based alerts tied to SLOs |
| No log retention policy set | Explicit hot/cold tiering with a deletion policy |
