---
name: infrastructure-as-code
description: Use when provisioning cloud or platform infrastructure declaratively — writing Terraform/OpenTofu, Bicep, CloudFormation or Pulumi, structuring modules, or managing state
---

# Infrastructure as Code

## Overview

Provider-neutral principles for declarative infrastructure provisioning, with Terraform/OpenTofu as the primary tool (match whatever the project already uses — see `README.md`, `EXAMPLES.md`, and `references/terraform.md`). Alternative tools are covered in their own reference file for when the project is already committed to one.

## When to Use

- Provisioning or modifying cloud infrastructure (networking, compute, managed services, IAM)
- Structuring a module library for reuse across environments
- State management: locking, drift, import, migration between backends
- Reviewing IaC for security, blast radius, or maintainability issues

## Core Principles

**Declare desired state, don't script steps.** IaC describes what should exist, and the tool computes the diff — never shell out to imperative `aws`/`az`/`gcloud` CLI calls from inside a module to work around a missing resource type; that defeats plan/diff visibility and state tracking.

**One state, one owner.** Each piece of infrastructure is managed by exactly one IaC root module/stack. Two different pipelines or tools managing overlapping resources causes drift fights neither can win. If migrating ownership, import into the new tool and remove from the old one in the same change — never leave both managing the same resource.

**Modules encapsulate a reusable unit, not a single resource.** A module wrapping one resource type with pass-through variables adds indirection with no abstraction value. A module earns its existence when it bundles resources that are provisioned and lifecycle-managed together (a VPC with its subnets and route tables; an app service with its logging and alerting).

**Separate state per environment, same module source.** Dev/staging/prod each get their own state (own blast radius, own lock) but reference the same module code at a pinned version — environments differ only in variable values, not in forked module logic.

**Plan before apply, always, and read the plan.** A plan step that nobody reads is a formality, not a safeguard — review for unexpected deletes/replaces (especially of stateful resources: databases, volumes) before approving an apply, every time, not only for "big" changes.

## State Management

- **Remote backend with locking** (not local state) from the first commit — a backend (S3+DynamoDB, Terraform Cloud, GCS, Azure Storage) that supports locking prevents two concurrent applies from corrupting state.
- **State contains secrets** (resource attributes often include generated passwords/keys) — the backend needs the same access control and encryption-at-rest as a secrets store, and state must never be committed to version control.
- **Drift** (manual changes outside IaC) is detected by `plan` showing changes with no corresponding code diff — treat recurring drift as a process problem (someone is making manual changes) to fix at the source, not a reason to stop running `plan`.

## Blast-Radius Discipline

Before any apply affecting a shared or production environment: identify every resource the plan would destroy or replace (not just add/modify), and confirm each is intentional. A single mistyped reference can silently plan to replace a database when only a tag was meant to change — `prevent_destroy` lifecycle rules on genuinely irreplaceable resources (primary databases, buckets with no backup) make that class of mistake fail loudly instead of silently.

## References

- `README.md` — Terraform/OpenTofu operating model and command workflow
- `EXAMPLES.md` — practical Terraform patterns for AWS/Azure/GCP and shared module/state layouts
- `references/terraform.md` — Terraform/OpenTofu specifics: provider config, module structure, workspaces, `for_each` vs `count`, import, state surgery
- `references/bicep.md` — Azure Bicep specifics
- `references/cloudformation.md` — AWS CloudFormation specifics
- `references/pulumi.md` — Pulumi specifics (general-purpose language IaC)

Load only the reference matching the project's existing tool. Don't introduce a second IaC tool into a project without a stated reason — tool sprawl multiplies the operational surface for no benefit.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Local state file, no locking | Remote backend with locking from day one |
| Shelling out to CLI commands inside a module | Use the provider's native resource type, or a data source if read-only |
| One module per resource type | Module boundary = things provisioned/lifecycle-managed together |
| Approving an apply without reading the plan's destroy/replace list | Always check what's being destroyed or replaced, not just added |
| Two tools managing the same resource | Pick one owner; import-and-remove when migrating |
