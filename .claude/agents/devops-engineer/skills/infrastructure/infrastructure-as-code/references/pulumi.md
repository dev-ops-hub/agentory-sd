# Pulumi Reference

Infrastructure declared in a general-purpose language (TypeScript, Python, Go) rather than a DSL — same declarative-state model as Terraform underneath, with the host language's own module/package system standing in for Terraform's module registry.

## Structure (TypeScript example)

```typescript
import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

const config = new pulumi.Config();
const environment = config.require("environment");

const vpc = new aws.ec2.Vpc("app-vpc", {
  cidrBlock: "10.0.0.0/16",
  tags: { Environment: environment },
});

export const vpcId = vpc.id;
```

## State & Stacks

Pulumi "stacks" are the equivalent of Terraform workspaces/environments — each stack has its own state, backed by Pulumi Cloud, S3, or another supported backend. `pulumi config set` stores per-stack configuration (and `--secret` for encrypted values) rather than `.tfvars` files.

```bash
pulumi stack select prod
pulumi config set --secret dbPassword "..."
pulumi preview   # the plan equivalent — always read before `pulumi up`
pulumi up
```

## When This Fits Better Than a DSL

Pulumi's main advantage is reusing the host language's actual control flow, type system, and package ecosystem for infrastructure logic (loops, conditionals, shared libraries, unit tests on infra code) rather than a DSL's more limited expressiveness. It fits a team already fluent in the chosen language and wanting infra code reviewed/tested like application code; it does not fit a team wanting infra config to stay declarative and readable by non-programmers.

## Common Mistakes

| Mistake | Fix |
|---|---|
| `pulumi up` without `pulumi preview` first | Always preview, read the diff, same discipline as `terraform plan` |
| Storing secrets as plain config values | Use `pulumi config set --secret` |
| Writing complex imperative logic that fights the declarative resource graph | If the logic is genuinely imperative (polling, retries outside resource creation), that belongs in application/operational tooling, not the Pulumi program |
