---
name: github-actions
description: Use when authoring or debugging a GitHub Actions workflow — triggers, job dependencies, matrix builds, caching, reusable workflows, or OIDC cloud auth
---

# GitHub Actions

## Overview

Concrete workflow YAML patterns for GitHub Actions. Pipeline *shape* (stages, gates, rollout strategy) comes from `skills/cicd/cicd-architecture` first — this skill is the syntax to implement that shape on this platform.

## When to Use

- Writing or reviewing a `.github/workflows/*.yml` file
- A workflow is slow (missing cache), flaky (race between jobs), or using long-lived cloud credentials instead of OIDC
- Needing a matrix build, a reusable workflow, or environment-gated deployment

## Core Pattern: build → test → scan → publish → deploy

```yaml
name: ci
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  id-token: write   # required for OIDC cloud auth; omit if unused

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - id: build
        uses: docker/build-push-action@v6
        with:
          push: false
          tags: app:${{ github.sha }}

  test:
    needs: build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node: ['18', '20']
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
          cache: 'npm'
      - run: npm ci
      - run: npm test

  publish:
    needs: [build, test]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:${{ github.sha }}

  deploy-staging:
    needs: publish
    runs-on: ubuntu-latest
    environment: staging   # environment protection rules gate this job
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/gha-staging-deploy
          aws-region: us-east-1
      - run: ./deploy.sh staging ${{ github.sha }}
```

## Patterns Worth Naming Explicitly

**OIDC over long-lived credentials.** `permissions: id-token: write` plus a cloud-side trust policy scoped to the repo/branch replaces a stored `AWS_ACCESS_KEY_ID` secret entirely — no credential to rotate or leak. Configure the trust policy's `sub` claim to the specific repo and ref, not a wildcard.

**`environment:` for approval gates.** A job with `environment: production` honors that environment's required-reviewer and wait-timer protection rules configured in repo settings — this is where the approval gate from `cicd-architecture` lives, not in workflow YAML conditionals.

**Caching.** `actions/setup-node`'s `cache:` input (or `actions/cache` directly for other ecosystems) keyed on the lockfile hash avoids re-downloading dependencies every run; a cache miss should degrade gracefully, never fail the job.

**Reusable workflows** (`workflow_call`) for logic shared across repos/pipelines, versus **composite actions** for a shared sequence of steps within one workflow. Don't duplicate the same job across 5 workflow files — extract a reusable workflow once 2+ real consumers exist.

**Concurrency control** to cancel superseded runs on the same ref:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Storing a cloud access key as a repo secret | Use OIDC (`id-token: write` + cloud trust policy) |
| One giant job instead of `needs:`-chained jobs | Split by responsibility so failures isolate and parallelize where independent |
| No `concurrency:` group on a workflow triggered by pushes | Add one, or old runs waste minutes and can race a newer deploy |
| Secrets printed via `run: echo ${{ secrets.X }}` for debugging | Never echo secrets; GitHub masks known secret values but this is not guaranteed for derived/transformed values |
| `pull_request_target` or exposing secrets to workflows triggered by fork PRs | Use `pull_request` (no secrets) for untrusted code; only use `pull_request_target` with explicit checkout of the base ref, never checking out and running the fork's code with secrets available |
