---
name: supply-chain-security
description: Use when a pipeline needs to produce an SBOM, sign artifacts, verify dependency provenance, or gate a build on vulnerability scan results
---

# Supply-Chain Security

## Overview

Protecting the path from source code to running artifact: knowing what's in a build (SBOM), proving where it came from (provenance/signing), and catching known-vulnerable dependencies before they ship.

## When to Use

- A pipeline needs a vulnerability-scan gate (container image or dependency tree)
- Compliance or a customer requires an SBOM per release
- Deciding whether and how to sign build artifacts
- Reviewing whether a build process is reproducible and tamper-resistant

## SBOM (Software Bill of Materials)

Generate one per release artifact, in CycloneDX or SPDX format, listing every direct and transitive dependency with version and license:

```yaml
- name: Generate SBOM
  run: syft $IMAGE -o cyclonedx-json=sbom.json
- name: Scan SBOM for known vulnerabilities
  run: grype sbom:sbom.json --fail-on high
```

Store the SBOM alongside the artifact (registry attestation, or a release asset) — it's useless if generated but discarded; a later disclosed CVE needs it to answer "are we affected" without re-scanning historical builds.

## Vulnerability Scanning Gates

| Gate | What it catches | Where |
|---|---|---|
| SAST (static analysis) | Code-level bugs (injection, hardcoded secrets) | Source, pre-build |
| Dependency scan | Known-CVE libraries | Build, against lockfile/SBOM |
| Container image scan | OS package + layer vulnerabilities | Post-build, pre-publish |

Gate on **severity threshold**, not zero findings: a zero-tolerance gate on a container base image blocks every build once a new CVE lands in an unrelated system library, which happens continuously. Fail on CRITICAL/HIGH with a documented, time-boxed exception process for anything accepted as a risk (an unpatchable transitive dependency with no exploit path in this context), not a silent allowlist that never gets revisited.

## Signing and Provenance

**Sign container images** (Cosign/Sigstore) so a deploy-time admission check can verify the image was produced by this pipeline and hasn't been swapped in the registry:

```bash
cosign sign --key cosign.key $IMAGE@$DIGEST
cosign verify --key cosign.pub $IMAGE@$DIGEST   # at deploy time, or via admission controller
```

Keyless signing (Sigstore Fulcio + Rekor transparency log, tied to the CI identity via OIDC) avoids managing a long-lived signing key at all — prefer it over a stored private key unless the platform doesn't support OIDC-based signing.

**SLSA provenance**: attest *how* an artifact was built (which pipeline, which source commit, which inputs) as a signed, verifiable statement attached to the artifact. GitHub's `actions/attest-build-provenance` and GitLab's built-in artifact attestation both produce this without hand-rolling the attestation format.

## Dependency Pinning

Lockfiles (`package-lock.json`, `poetry.lock`, Terraform `.terraform.lock.hcl`) pin exact resolved versions — commit them, and fail CI if the lockfile is out of sync with the manifest (`npm ci` enforces this; `npm install` does not). For base images, pin by digest (`FROM node:20@sha256:...`) rather than a mutable tag, so a build is reproducible even if the tag is later repointed upstream.

## Deliverables for a supply-chain security task

1. SBOM generation step, with the format and storage location
2. Scan gate with its severity threshold and exception process
3. Signing/provenance mechanism if the artifact crosses a trust boundary (external registry, third-party deploy target)

## Common Mistakes

| Mistake | Fix |
|---|---|
| Zero-vulnerability gate on container base images | Gate on severity threshold with a documented exception process |
| Generating an SBOM but not storing it | Attach it to the release/registry so it's queryable later |
| Floating base image tags (`node:latest`) | Pin by digest |
| Stored long-lived signing private key when OIDC/keyless signing is available | Use Sigstore keyless signing tied to CI identity |
