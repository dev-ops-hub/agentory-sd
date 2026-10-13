---
name: gitlab-ci
description: Use when authoring or debugging a GitLab CI pipeline — stages, rules, DAG needs, caching, or GitOps-style Kubernetes deployment
---

# GitLab CI

## Overview

Concrete `.gitlab-ci.yml` patterns. Pipeline *shape* comes from `skills/cicd/cicd-architecture` first — this skill is the GitLab-specific syntax to implement it.

## When to Use

- Writing or reviewing `.gitlab-ci.yml`
- Choosing between `stages:` ordering and a `needs:`-based DAG for job dependencies
- Setting up environment-gated deploys or a GitOps deploy to Kubernetes

## Core Pattern: build → test → scan → publish → deploy

```yaml
stages: [build, test, scan, publish, deploy]

variables:
  IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

build:
  stage: build
  image: docker:24
  services: [docker:24-dind]
  script:
    - docker build -t $IMAGE .
    - docker save $IMAGE -o image.tar
  artifacts:
    paths: [image.tar]
    expire_in: 1 hour

test:
  stage: test
  needs: [build]
  script:
    - npm ci
    - npm test
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main"'

scan:
  stage: scan
  needs: [build]
  script:
    - trivy image --exit-code 1 --severity CRITICAL,HIGH --input image.tar

publish:
  stage: publish
  needs: [test, scan]
  image: docker:24
  services: [docker:24-dind]
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
  script:
    - docker load -i image.tar
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $IMAGE

deploy-staging:
  stage: deploy
  needs: [publish]
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - kubectl set image deployment/app app=$IMAGE -n staging

deploy-prod:
  stage: deploy
  needs: [deploy-staging]
  environment:
    name: production
  when: manual   # the approval gate from cicd-architecture
  script:
    - kubectl set image deployment/app app=$IMAGE -n production
```

## Patterns Worth Naming Explicitly

**`needs:` over implicit stage ordering** when jobs within or across stages are actually independent — `stages:` alone serializes everything in a stage's predecessor stage even when no real dependency exists, wasting pipeline time. `needs:` builds the actual DAG.

**`rules:` over `only`/`when` combinations.** `only`/`when` are deprecated and compose poorly; `rules:` is the single mechanism for conditional job inclusion and should be used exclusively in new pipelines.

**`environment:` for deploy tracking and manual gates.** `when: manual` on a job with `environment: production` is GitLab's approval gate — paired with Protected Environments (repo settings) restricting who can click "run" on it.

**GitOps instead of `kubectl` from CI** for anything beyond a demo: have CI update an image tag in a Git-tracked manifest/Helm-values repo and let Argo CD/Flux reconcile the cluster, rather than giving the CI runner a cluster-admin kubeconfig. This removes long-lived cluster credentials from CI entirely — see `skills/containers/kubernetes` for the GitOps reconciliation side.

**Caching** via `cache:` keyed on a dependency lockfile, scoped per-branch (`key: files: [package-lock.json]`) to avoid cross-branch cache poisoning.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Giving the CI runner a long-lived cluster-admin kubeconfig | Use GitOps reconciliation (Argo CD/Flux) or a short-lived, narrowly-scoped service account token |
| `only`/`when` for conditionals in new pipelines | Use `rules:` |
| One shared `cache:` key across all branches | Scope the key to the branch or the lockfile hash |
| Secrets as plain CI/CD variables instead of masked + protected | Mark variables both `Masked` and `Protected`, restricting them to protected branches/tags |
