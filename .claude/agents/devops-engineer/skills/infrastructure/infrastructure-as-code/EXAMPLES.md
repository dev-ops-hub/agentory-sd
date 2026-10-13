# Terraform Infrastructure Examples

Curated examples for Terraform/OpenTofu patterns commonly used by this repository's DevOps workflows.

## Table of Contents

1. AWS VPC baseline
2. Reusable module layout
3. Multi-environment deployment
4. Remote state backend
5. Import and refactor workflow

## Example 1: AWS VPC Baseline

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

Use as a base, then layer subnets, route tables, and security controls.

## Example 2: Reusable Module Layout

```text
modules/
  network/
    main.tf
    variables.tf
    outputs.tf
  app/
    main.tf
    variables.tf
    outputs.tf
environments/
  dev/
  prod/
```

```hcl
module "network" {
  source      = "../../modules/network"
  cidr_block  = var.vpc_cidr
  environment = var.environment
}
```

## Example 3: Multi-Environment Deployment

```hcl
locals {
  env = terraform.workspace
  sizing = {
    dev  = { count = 1, type = "t3.micro" }
    prod = { count = 4, type = "t3.large" }
  }
}

resource "aws_instance" "app" {
  count         = local.sizing[local.env].count
  instance_type = local.sizing[local.env].type
  ami           = data.aws_ami.base.id
}
```

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform plan
```

For high-risk environments, prefer directory-per-environment for stronger separation.

## Example 4: Remote State Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "org-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

Backend requirements:

- encryption at rest
- lock support
- access controls equivalent to secrets storage
- versioning for recovery

## Example 5: Import and Refactor Workflow

```bash
# import existing infrastructure
terraform import aws_s3_bucket.logs my-existing-logs-bucket

# refactor resource address without recreation
terraform state mv aws_instance.app aws_instance.app_primary

# validate refactor safety
terraform plan
```

Always run `plan` after `import` or `state` operations and verify no unintended replaces/destroys.
