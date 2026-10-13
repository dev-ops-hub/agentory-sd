---
name: cicd-architecture
description: Use when designing a build/release pipeline's stages, approval gates, or rollout strategy, or when environment promotion or rollback behavior is unclear
---

# CI/CD Architecture

## Overview

How to shape a pipeline before writing its YAML: stage ordering, what gates each promotion, which rollout strategy fits the risk, and how rollback actually triggers. Platform-specific syntax lives in `skills/cicd/github-actions` and `skills/cicd/gitlab-ci`.

## When to Use

- Designing a new pipeline from scratch, or restructuring one that's grown ad hoc
- Deciding how an environment promotion (dev → staging → prod) should gate
- Choosing a rollout strategy (rolling, blue-green, canary) for a given risk/traffic profile
- Defining what "rollback" means for a specific deployment target

## Stage Design

A pipeline is a sequence of stages, each with a single responsibility and a clear pass/fail signal:

1. **Build** — compile/package, produce one immutable artifact (container image, binary, build output) tagged with a content-derived identifier (commit SHA or digest), never `latest`.
2. **Test** — fast feedback first (lint, unit) before slow feedback (integration, e2e). Fail fast: don't run e2e against a build that fails lint.
3. **Scan** — SAST, dependency/SBOM, image vulnerability scan (see `skills/cicd/supply-chain-security`). Gate on severity, not presence — zero-vuln gates block indefinitely as new CVEs land in unrelated base images.
4. **Publish** — push the immutable artifact to a registry, once, before any environment deploy. Every environment deploys the *same* artifact; never rebuild per environment.
5. **Deploy (per environment)** — apply the published artifact to an environment, in promotion order.

The one artifact, many deploys rule is the single most common CI/CD architecture bug: rebuilding per environment lets environment-specific config leak into what should be identical builds, and means prod never ran the exact bits staging verified.

## Environment Promotion

| Gate type | Use when | Example |
|---|---|---|
| Automatic | Low-risk environment, fast rollback available | dev auto-deploys on merge to main |
| Required approval | Change affects shared/paying users | prod requires a named approver |
| Time-boxed soak | Behavior under real traffic matters more than a human glance | staying in staging 1 hour with error-rate monitoring before prod eligibility |
| Scheduled window | Change-risk policy restricts when prod can change | no prod deploys Friday afternoon / during known high-traffic windows |

Promotion is one-directional and the artifact never changes between stages — only configuration (env vars, secret refs, replica counts) varies per environment, injected at deploy time, not baked into the build.

## Rollout Strategies

| Strategy | Mechanism | Fits when |
|---|---|---|
| Rolling update | Replace instances gradually, old and new serve traffic briefly together | Default choice; stateless services, backward-compatible changes |
| Blue-green | Full second environment stood up, traffic cut over atomically | Need instant, clean rollback; can afford 2x capacity briefly |
| Canary | Small traffic percentage to new version, expand on healthy signal | High-traffic services where a bad deploy must affect few users before being caught |
| Recreate | Terminate all old, then start new | Acceptable downtime, singleton/stateful workloads that can't run two versions |

Canary and blue-green both require the deployment target to support running two versions simultaneously; a database migration that isn't backward-compatible breaks this for canary and blue-green alike — see the migration note below.

## Rollback

Rollback is not "the opposite of deploy" — it is itself a deploy of a known-good artifact, and must go through the same path (same promotion gates can be fast-tracked, not skipped). Define, before the first production deploy of a service:

- **Trigger**: what automatically or manually initiates rollback — an error-rate/latency SLO breach (tie to `skills/observability/observability-platforms` alerting), a failed health check, or a human call.
- **Mechanism**: redeploy the previous artifact tag (requires registry retention and a traffic-cut mechanism — load balancer, service mesh, or orchestrator-native) vs. feature-flag kill switch (requires the flag to have existed before the risky change shipped — can't retrofit after the fact).
- **Database migrations**: forward-only migrations (never roll back schema) with code that tolerates both old and new schema during the deploy window is the only rollback-safe pattern for stateful changes. A migration that drops a column breaks rollback for every version still running against it.

## Deliverables for a pipeline design task

1. Stage list with pass/fail criteria per stage
2. Promotion gate per environment transition, with named approvers/triggers
3. Rollout strategy per environment, with the reasoning
4. Rollback trigger and mechanism, including the migration-compatibility note if the service is stateful

## Common Mistakes

| Mistake | Fix |
|---|---|
| Rebuilding the artifact per environment | Build once, publish once, promote the same artifact |
| Tagging images `latest` | Tag by commit SHA or content digest |
| Treating rollback as untested until needed | Exercise the rollback path in a non-prod environment at least once |
| Canary/blue-green with an incompatible DB migration | Make migrations backward-compatible first, or fall back to recreate/rolling for that release |
