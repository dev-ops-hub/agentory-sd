---
name: designing-system-architecture
description: Use when designing, reviewing or costing a system or cloud architecture (AWS, Azure, GCP or on-prem) for a PRD, a client brief or an existing codebase, including when the brief is thin, a budget figure is wanted, or the caller cannot answer questions
---

# Designing System Architecture

## Overview

The output of an architecture task is the design document in [references/TEMPLATE.md](references/TEMPLATE.md), filled in. Its sections are fixed; every slot marked REQUIRED is present in every design, even when the brief is thin.

Core principle: **a reader can trace every figure, target and choice to its source**: the brief, a cited document, or a numbered assumption.

## When to Use

- A new design from a PRD (`planning/product-req-document(PRD).md`) or a client brief
- A review of an existing architecture or codebase
- A cost or budget estimate for a system

Not for: a single technology question (answer it directly with one comparison table and one ADR).

## Workflow

1. Read the governing constraints first: `planning/constitution.md` and the PRD when they exist. If the request conflicts with a MUST rule, return the conflict (rule, conflicting request, options for the user) instead of a design.
2. Read `multi-cloud-architect` for the target platform (its provider-detection step picks the right reference) and the `develop-adr` template.
3. Fill in TEMPLATE.md top to bottom.
4. Check the result against the Quick Reference before returning. Reconcile the diagram (2.3), the resource inventory (3.1) and the traffic matrix (4.2) so each lists the same resources and flows.

| Target | Read |
|---|---|
| Any cloud: styles, 44 design patterns, decision frameworks, security model | `multi-cloud-architect/SKILL.md`, `references/architecture-principles.md`, `references/design-patterns.md` |
| Azure specifics (services, identity, networking, WAF) | `multi-cloud-architect/references/azure.md` |
| AWS specifics (services, identity, networking, Well-Architected) | `multi-cloud-architect/references/aws.md` |
| GCP specifics (services, identity, networking, Architecture Framework) | `multi-cloud-architect/references/gcp.md` |
| Every decision record | `develop-adr` |

## Quick Reference: slots reviewers check

| Slot | Filled when |
|---|---|
| Basis column (sections 1, 6) | Each number shows `brief`, `PRD §x`, `<source>, retrieved <date>`, or `ASSUMPTION A<k>` |
| Trade-off matrix (section 6) | At least two options as columns; rows include Cost, Latency, Operational complexity |
| Diagrams | Every diagram is a ```` ```mermaid ```` block: context and container views (2.1, 2.2), the nested network and subnet topology (2.3), the software component view (3.2), a sequence for the critical path (4) |
| Resource inventory (3.1) | Every resource in the 2.3 diagram has a row with its subnet and CIDR, and every row appears in the diagram |
| Traffic matrix (4.2) | Every edge in the 2.3 diagram has a flow ID, protocol, port, encryption and the rule that allows it |
| Software architecture (3.2) | Layers, module responsibilities, service APIs and data ownership are named, not implied |
| ADRs (section 7) | One per decision that is costly to reverse, in the `develop-adr` Nygard shape, Status `Proposed` |
| Gaps (section 8) | Every assumption that moves cost, scope or a target by a meaningful amount appears as a `Q<k>` with its impact |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Prices from memory presented as figures | Cite the pricing page and date, or tag `ASSUMPTION A<k>` with the basis (size, region, tier) |
| Decisions buried in table rows | Promote each costly-to-reverse choice to an ADR in section 7 |
| Open questions spread through prose | Collect them as `Q<k>` items in section 8 so the caller can relay them |
| Diagram stops at the container level | Go down to subnets, CIDRs, zones and security boundaries (2.3); a box named "VPC" is not a topology |
| Resources in the diagram but not the inventory (or the reverse) | Reconcile 2.3, 3.1 and 4.2 before returning |
| Asking the user what the PRD or the product manager can answer | Tag it `[PM]`; only budget, accounts, compliance and existing infrastructure are `[USER]` |
| Enterprise defaults (multi-region, service mesh) for a small system | Size to the NFR baseline; put the bigger option in the matrix as the scaling path |
