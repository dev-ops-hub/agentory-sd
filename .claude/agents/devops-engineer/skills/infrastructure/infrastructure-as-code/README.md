# Terraform Infrastructure-as-Code

Terraform/OpenTofu guide for building, operating, and reviewing cloud infrastructure using declarative configuration and repeatable workflows.

## Overview

Use this alongside `SKILL.md` and `references/terraform.md` when the project uses Terraform/OpenTofu.

This README mirrors the same high-level shape used by `terraform-infrastructure` style skills:

- What Terraform/OpenTofu is for
- Core workflow
- Project structure patterns
- Essential commands
- Best-practice checklist

## Core Workflow

1. Write declarative `.tf` code.
2. Initialize providers and backend (`terraform init`).
3. Validate and format (`terraform validate`, `terraform fmt -recursive`).
4. Plan (`terraform plan -out=tfplan`) and review adds/changes/destroys.
5. Apply reviewed plan (`terraform apply tfplan`).
6. Verify outputs, drift posture, and policy checks.

## Project Structure

### Basic Project

```text
my-infrastructure/
├── main.tf             # Primary resources
├── variables.tf        # Input variables
├── outputs.tf          # Output values
├── terraform.tfvars    # Variable values (gitignore when sensitive)
├── versions.tf         # Provider/version constraints
└── README.md           # Documentation
```

### Module-Based Project

```text
terraform-infrastructure/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   │   └── ...
│   └── production/
│       └── ...
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── compute/
│   │   └── ...
│   ├── database/
│   │   └── ...
│   └── networking/
│       └── ...
├── global/
│   ├── iam/
│   │   └── main.tf
│   └── route53/
│       └── main.tf
└── README.md
```

Use one state per environment and keep module sources shared and versioned.

## Essential Commands

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform workspace list
terraform state list
terraform import <resource.address> <resource-id>
```

## Best-Practice Checklist

- Pin provider versions and commit `.terraform.lock.hcl`.
- Use remote backend with locking and encryption.
- Never commit state files or secret tfvars.
- Prefer `for_each` over unstable `count` indexing.
- Enforce lint/security checks in CI.
- Treat plan review as a production safety gate.

## Related Files

- `SKILL.md` - provider-neutral IaC operating rules
- `EXAMPLES.md` - practical templates and patterns
- `references/terraform.md` - Terraform/OpenTofu deep reference
- `references/bicep.md`, `references/cloudformation.md`, `references/pulumi.md` - alternative IaC tools
