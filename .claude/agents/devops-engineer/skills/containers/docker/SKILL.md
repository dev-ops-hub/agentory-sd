---
name: docker
description: Use when writing or reviewing a Dockerfile, structuring a build for size/cache efficiency, or managing container registries and image scanning
---

# Docker

## Overview

Building, hardening and distributing container images. Standardizes what `software-engineer` hands over as "a Dockerfile and the app's runtime requirements" into a production-shaped build.

## When to Use

- Writing or reviewing a Dockerfile
- An image is too large, builds too slowly, or rebuilds from scratch when only app code changed
- Setting up a registry, retention policy, or image scan gate
- A container runs as root, or a build leaks a build-time secret into a layer

## Multi-Stage Builds

Separate the build toolchain from the runtime image — the final image ships only what's needed to run, not the compiler/package manager/dev dependencies that built it:

```dockerfile
# Build stage: full toolchain, discarded after this stage
FROM node:20 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage: minimal base, only the build output
FROM node:20-slim AS runtime
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
COPY package*.json ./
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node healthcheck.js
CMD ["node", "dist/main.js"]
```

## Layer Caching

Order instructions from least-to-most frequently changing: base image → system deps → dependency manifest + install → application code. Copying the dependency manifest (`package.json`/`requirements.txt`) and installing *before* copying application source means a code-only change doesn't invalidate the dependency-install layer, which is usually the slowest step.

```dockerfile
# Wrong: any source change invalidates the dependency install cache
COPY . .
RUN npm ci

# Right: dependency layer only invalidates when the manifest changes
COPY package*.json ./
RUN npm ci
COPY . .
```

## Security Hardening

- **Non-root user**: `USER node` (or a created non-root user for images without one) — a container compromise that would otherwise have root inside the container is contained to that unprivileged user's capabilities.
- **No secrets in layers**: `ARG`/`ENV` values and anything `COPY`'d are visible in `docker history` and the image itself even if a later layer deletes the file — a secret needed only at build time belongs in a build-stage-only `RUN --mount=type=secret`, never a plain `ARG`.
- **Minimal base image**: `-slim`/`-alpine`/distroless variants reduce both image size and attack surface (fewer installed packages = fewer CVEs to track). Distroless (no shell, no package manager) is the strongest option when the runtime genuinely needs nothing beyond the language runtime.
- **Pin the base image by digest** for reproducibility, consistent with `skills/cicd/supply-chain-security`.

```dockerfile
# Leaks the secret into the image layer history permanently
ARG NPM_TOKEN
RUN echo "//registry.npmjs.org/:_authToken=${NPM_TOKEN}" > .npmrc && npm ci

# Secret only exists in the build container's memory for this RUN, never in a layer
RUN --mount=type=secret,id=npm_token \
    NPM_TOKEN=$(cat /run/secrets/npm_token) npm ci
```

## Docker Compose for Local/Dev Orchestration

Compose is for local development and simple single-host deployments, not a production multi-node orchestration answer — see `skills/containers/kubernetes` for that. A dev-shaped Compose file still deserves health checks and explicit networks so it catches integration issues before they surface in a real cluster:

```yaml
services:
  app:
    build: .
    depends_on:
      db: { condition: service_healthy }
    environment:
      DATABASE_URL: postgres://db:5432/app
  db:
    image: postgres:16-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      retries: 5
    volumes:
      - db-data:/var/lib/postgresql/data
volumes:
  db-data:
```

## Registries and Scanning

- Tag by immutable identifier (commit SHA/digest) for anything deployed; `latest` is for local dev convenience only, never for a deployment reference (see `skills/cicd/cicd-architecture`'s one-artifact rule).
- A retention policy (delete untagged/old images past N days) keeps registry costs and attack surface bounded — unbounded retention of every build is rarely intentional.
- Image scanning (Trivy, Grype, or the registry's native scanner) at push time, gated per `skills/cicd/supply-chain-security`'s severity-threshold guidance, not zero-tolerance.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Single-stage build shipping the full build toolchain | Multi-stage build, minimal runtime base |
| `COPY . .` before dependency install | Copy manifest, install, then copy source |
| Running as root in the final image | Add/use a non-root `USER` |
| Secret passed via `ARG`/`ENV` baked into a layer | `RUN --mount=type=secret` (build-time only, never persisted) |
| No `HEALTHCHECK` | Add one — orchestrators and Compose both use it for readiness |
