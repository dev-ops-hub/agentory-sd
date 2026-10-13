# Terraform / OpenTofu Reference

OpenTofu is a drop-in-syntax fork of Terraform (post-license-change); everything here applies to both unless noted. Default to whichever the project already uses.

## When to Use

- Provisioning or changing cloud infrastructure on AWS, Azure, GCP, Kubernetes, or hybrid stacks
- Building reusable module libraries for teams
- Managing state across multiple environments and contributors
- Importing manual resources into IaC ownership and reducing drift

## Core Workflow

```text
Write -> Init -> Validate -> Plan -> Apply -> Verify
```

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Always review the destroy/replace set in `plan` before approving apply.

## Project Structure

### Basic Project

```text
my-infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
└── README.md
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
│   ├── compute/
│   ├── database/
│   └── networking/
├── global/
│   ├── iam/
│   └── route53/
└── README.md
```

Prefer module-based layout for multi-team and multi-environment infrastructure.

## Provider and Backend Configuration

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "my-tfstate"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = { ManagedBy = "terraform", Environment = var.environment }
  }
}
```

Pin provider versions with `~>` (allow patch/minor, not major) and commit the `.terraform.lock.hcl` file — it pins the exact provider build, same role as a dependency lockfile.

Use remote backend + locking from the first shared environment; local state is for isolated experimentation only.

## HCL Patterns That Matter

### Variables with validation

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}
```

### Locals for shared metadata

```hcl
locals {
  common_tags = {
    ManagedBy   = "terraform"
    Environment = var.environment
    Project     = var.project
  }
}
```

### Meta-arguments

- Use `for_each` for stable keyed resources
- Use `lifecycle` (`create_before_destroy`, `prevent_destroy`, `ignore_changes`) deliberately
- Use `depends_on` only when implicit dependency inference is insufficient

## Module Structure

```
modules/
  vpc/
    main.tf       # resources
    variables.tf  # inputs, with type + description + validation
    outputs.tf    # what other modules/roots consume
    README.md
environments/
  staging/
    main.tf       # calls modules/vpc with staging values
    backend.tf    # staging's own state backend config
  prod/
    main.tf       # calls the SAME module source/version, prod values
    backend.tf
```

```hcl
module "vpc" {
  source  = "../../modules/vpc"
  version = "1.4.0"   # if sourced from a registry; for local/git sources, pin a tag/ref instead
  cidr_block  = var.cidr_block
  environment = var.environment
}
```

Module guidelines:

- A module should encapsulate a lifecycle unit, not one thin resource wrapper
- Every module publishes explicit `inputs` and `outputs`
- Keep module documentation (`README.md`) current with examples

## `for_each` vs `count`

Prefer `for_each` over `count` for anything keyed by a stable identifier (a map of subnet-name → CIDR): `count` indexes by position, so removing an item from the middle of a list shifts every subsequent resource's index and triggers spurious destroy/recreate. `for_each` only touches the actual removed key.

```hcl
# Fragile: removing "b" shifts "c"'s index, forcing a replace
resource "aws_subnet" "s" {
  count = length(var.subnets)
  cidr_block = var.subnets[count.index]
}

# Stable: removing "b" only destroys "b"'s resource
resource "aws_subnet" "s" {
  for_each   = var.subnets   # map(string), keyed by name
  cidr_block = each.value
}
```

## Workspaces vs. Directory-per-Environment

Terraform workspaces (`terraform workspace new staging`) share one backend config and module source but isolate state per workspace — convenient, but all workspaces must use identical variable *structure* (just different values), and a mistaken `terraform workspace select` before an apply is a common blast-radius accident. Directory-per-environment (shown above) is more explicit and harder to apply-to-the-wrong-environment by accident; prefer it for anything with meaningfully different prod safeguards (approval requirements, `prevent_destroy`).

## State Management

- State contains sensitive and operationally critical data; treat backend security as production-grade
- Enable backend encryption and versioning
- Enable locking (`dynamodb_table`, blob lease, or Terraform Cloud equivalent)
- Back up state before major refactors or backend migration
- Run `plan` after every state operation (`import`, `state mv`, `state rm`)

### Common backend patterns

- AWS: S3 + DynamoDB lock table + KMS encryption
- Azure: Blob backend with state container and RBAC
- GCP: GCS backend with object versioning
- Terraform Cloud/Enterprise: workspace-backed remote state and run policies

## Import & State Surgery

```bash
# Bring an existing, manually-created resource under Terraform management
terraform import aws_s3_bucket.logs my-existing-bucket-name

# Move a resource within state without destroying/recreating it (e.g. after a refactor)
terraform state mv aws_instance.old aws_instance.new

# Remove a resource from state without destroying the real infrastructure
# (e.g. ownership is moving to another tool/team)
terraform state rm aws_instance.transferred
```

Always run `terraform plan` immediately after any `state` surgery command before the next real apply — confirm the plan shows no unintended changes resulting from the state edit.

## Security and Governance

- Never hardcode credentials; use cloud-native identity or CI OIDC
- Mark secret variables as `sensitive = true`
- Keep `.tfvars` with secrets out of VCS
- Enforce lint/security policy in CI (`tflint`, `checkov`, `tfsec`/`terrascan`)
- Use PR approval gates for production applies

## Essential Commands

```bash
# Formatting and validation
terraform fmt -recursive
terraform validate

# Planning and applying
terraform plan -out=tfplan
terraform apply tfplan

# Workspace operations
terraform workspace list
terraform workspace select prod

# State and import
terraform state list
terraform import aws_instance.web i-1234567890abcdef0
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| `count` on a list that items get removed from mid-list | `for_each` keyed by a stable identifier |
| No provider version constraint | Pin with `~>` and commit the lock file |
| One workspace set for environments with different safety requirements | Directory-per-environment, explicit about which has `prevent_destroy` |
| `terraform apply` without reviewing `plan` output | Always read the plan, especially the destroy/replace list |
| State backend with no lock/encryption/versioning | Configure locking and encryption before team usage |
| Secrets in `.tfvars` checked into git | Keep secrets in secret manager/CI vars and gitignore sensitive tfvars |
