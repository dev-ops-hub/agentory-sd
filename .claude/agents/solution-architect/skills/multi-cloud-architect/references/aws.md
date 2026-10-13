# AWS Implementation Reference

AWS-specific services, identity model, networking model, and Well-Architected
Framework. Read `architecture-principles.md`, `design-patterns.md`, `security.md`, and
`decision-frameworks.md` for the provider-neutral reasoning this file plugs into.

---

## Identity

AWS splits identity into two distinct layers rather than Azure's single unified
platform — don't map Entra ID 1:1 onto either half:

- **AWS IAM** — resource-permission control plane: users, groups, roles, policies.
  Scoped to permissions on resources, not primarily a workforce directory.
- **IAM Identity Center** (formerly AWS SSO) — workforce SSO across AWS accounts and
  supported third-party apps; the closer analogue to "centralized human identity," but
  it's a separate product from IAM itself.
- **IAM roles** (not static access keys) are the default for workload-to-workload auth:
  EC2 instance profiles, Lambda execution roles, ECS task roles, EKS IRSA (IAM Roles for
  Service Accounts) — all grant temporary, auto-rotated credentials with no key material
  to store.
- **AWS Secrets Manager** — secrets, with automatic rotation support for common database
  engines.
- **AWS KMS** — key management, encryption at rest.
- **AWS Organizations + SCPs** — account-level governance and permission boundaries
  across an org.
- Federation: SAML 2.0 and OIDC supported via IAM Identity Center or IAM identity
  providers; cross-account access via assumed roles with external ID conditions.

## Networking

- **Amazon VPC is a regional resource** (same regional scope as Azure VNet — unlike
  GCP's global VPC). Subnets are tied to a single Availability Zone within the VPC's
  region.
- **AWS commercial regions guarantee at least 3 Availability Zones** — a stronger
  baseline guarantee than Azure (not every Azure region has AZs). Spread subnets and
  resources across AZs for the standard HA pattern.
- **Application Load Balancer (ALB)** — Layer 7, HTTP(S), supports path/host-based
  routing, target groups.
- **Network Load Balancer (NLB)** — Layer 4, TCP/UDP, very high throughput, static IP.
- **Amazon CloudFront** — global CDN, integrates with WAF and Shield.
- **AWS Global Accelerator** — anycast static IPs routing to the nearest healthy
  regional endpoint; Layer 4, global.
- **Route 53** — DNS, including latency-based and failover routing policies.
- **AWS PrivateLink** — private connectivity to AWS services and third-party SaaS
  without traversing the public internet (the AWS analogue to Azure Private Link / GCP
  Private Service Connect, though setup and scope differ).
- **AWS Shield (Standard/Advanced)** + **AWS WAF** — DDoS and web application
  protection.
- **Transit Gateway** — hub-and-spoke connectivity across many VPCs/VPNs/Direct
  Connect, the standard way to avoid an unmanageable full-mesh VPC peering topology.

## Compute

The managed-service escalation path on AWS does not line up service-for-service with
Azure's VM→App Service→AKS ladder or GCP's Compute Engine→Cloud Run→GKE ladder:

| Service | Best For | Scale | Complexity | Cost Model |
|---|---|---|---|---|
| EC2 | Full control, custom OS, specialized instance types (GPU, HPC) | Manual / Auto Scaling Groups | High | Per-second, On-Demand/Reserved/Spot |
| AWS Lambda | Event-driven, short-lived functions | Automatic, massive concurrency | Very Low | Per invocation + duration |
| AWS Fargate | Serverless containers (ECS or EKS launch type) | Automatic per-task | Low-Medium | Per vCPU/memory-second |
| Amazon ECS | Container orchestration, AWS-native | Service autoscaling | Medium | EC2 or Fargate launch type |
| Amazon EKS | Full Kubernetes | Cluster/node-group autoscaling | High | Control plane fee + node cost |
| Elastic Beanstalk | PaaS-style app deployment, minimal ops | Built-in autoscaling | Low | Underlying EC2/resources cost |
| AWS Batch | Batch/HPC job scheduling | Managed compute environment autoscale | Medium | Underlying EC2/Fargate cost |

**Quick decision:**
- Full OS control or specialized hardware? → **EC2**
- Short-lived event-driven code? → **Lambda**
- Containers without managing servers? → **Fargate** (via ECS or EKS)
- AWS-native container orchestration, simpler than K8s? → **ECS**
- Need the Kubernetes API/ecosystem? → **EKS** (Fargate or EC2 node groups)
- Minimal-ops app deployment, don't want to think about infra? → **Elastic Beanstalk**
- Large-scale batch/HPC? → **AWS Batch**

**Important distinction:** Fargate is a *launch type*, not a separate product tier — it
applies to both ECS and EKS. Treating "EKS, Fargate, ECS" as three parallel rungs of one
ladder (the way Azure's AKS/Container Apps/Container Instances are sometimes read) is a
category error.

## Storage

| Service | Best For | Access Pattern | Scale |
|---|---|---|---|
| Amazon S3 | Unstructured data, backups, static hosting, data lake | REST API, SDK | Virtually unlimited |
| Amazon EBS | Block storage for a single EC2 instance | Block device | Per-volume, up to tens of TB |
| Amazon EFS | Shared NFS file storage across instances/AZs | File system mount (NFS) | Elastic, PB-scale |
| FSx | Managed Windows/Lustre/NetApp/OpenZFS file systems | File system mount | Varies by engine |
| S3 Glacier / Glacier Deep Archive | Cold archival storage | Retrieval-based | Virtually unlimited |

S3 storage classes (Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier
tiers) let you tier by access frequency automatically (Intelligent-Tiering) or
explicitly.

## Databases

| Service | Best For | Consistency | Scale |
|---|---|---|---|
| Amazon RDS | Managed relational (PostgreSQL, MySQL, MariaDB, Oracle, SQL Server) | Strong (ACID) | Multi-AZ for HA, read replicas for read scale |
| Amazon Aurora | MySQL/PostgreSQL-compatible, cloud-native relational | Strong (ACID) | Aurora Global Database for cross-region |
| Amazon DynamoDB | Key-value / document NoSQL, single-digit-ms latency at scale | Tunable (eventual or strongly consistent reads) | Virtually unlimited horizontal |
| Amazon ElastiCache | In-memory cache (Redis or Memcached) | N/A (cache) | Cluster mode for horizontal scale |

**Multi-region write behavior is service-specific, not a blanket AWS answer:**
- **Aurora Global Database** replicates across regions with typically sub-second lag,
  but writes go to a single primary region — it is not multi-region active-active
  writes, it's fast cross-region replication for read scale-out and fast failover.
  Aurora now also supports a limited multi-writer configuration within a single region.
- **DynamoDB global tables** support true multi-region, multi-active writes with
  last-writer-wins conflict resolution — the AWS analogue closest to Cosmos DB's or
  Spanner's multi-region write story, but for a key-value/document model, not relational.
- Don't assume "AWS's relational database" behaves like either extreme — check the
  specific service and configuration.

## Messaging / Integration

| Service | Best For | Delivery Model |
|---|---|---|
| Amazon SQS | Simple decoupling queue (standard or FIFO) | At-least-once (standard), exactly-once processing (FIFO) |
| Amazon SNS | Pub/sub fan-out notifications | At-least-once, push-based |
| Amazon EventBridge | Event-driven routing, SaaS/AWS service event sources, scheduling | At-least-once |
| Amazon MSK | Managed Apache Kafka | Ordered, partitioned streaming |
| Amazon Kinesis | Real-time data streaming, analytics ingestion | Ordered, partitioned streaming |
| AWS Step Functions | Workflow orchestration (Scheduler Agent Supervisor / Saga patterns) | Managed state machine |

## API Management

- **Amazon API Gateway** — REST and HTTP APIs, request validation, authorizers (Lambda
  or JWT), usage plans/throttling, native integration with Lambda/Step Functions/other
  AWS services.
- For a managed developer-portal-style full API management layer (closer to Azure API
  Management's scope), API Gateway plus supporting services, or a third-party layer, is
  typically combined — API Gateway alone doesn't cover every API Management feature.

## AI/ML

| Service | Best For |
|---|---|
| Amazon Bedrock | Foundation models (multiple providers) via a managed API |
| Amazon SageMaker | Custom ML model training, tuning, and MLOps |
| AI-specific services (Rekognition, Comprehend, Transcribe, etc.) | Pre-built, narrow AI capabilities |

## Observability

- **Amazon CloudWatch** — metrics, logs, alarms, dashboards.
- **AWS X-Ray** — distributed tracing.
- **AWS CloudTrail** — API-call audit logging (account/organization level).

## Infrastructure as Code / CI-CD

- **AWS CloudFormation** — native IaC (also underlies the AWS CDK, which generates
  CloudFormation from TypeScript/Python/etc.).
- **AWS CodePipeline / CodeBuild / CodeDeploy**, or GitHub Actions — CI/CD.

## Governance / Cost

- **AWS Trusted Advisor** — cost, performance, security, fault-tolerance, service-limit
  recommendations (the AWS analogue to Azure Advisor, with different check coverage).
- **AWS Cost Explorer / Budgets** — cost analysis and budget alerting.
- **AWS Organizations + Service Control Policies (SCPs)** — governance guardrails
  across accounts.
- **Reserved Instances / Savings Plans / Spot Instances** — commitment-based and
  interruption-tolerant discounting, with no exact Azure/GCP equivalent in commitment
  structure — compare the actual terms, not just "reservations exist on all three."

## Resilience / HA / DR

- **AWS Fault Injection Simulator (FIS)** — fault injection and chaos experiments (the
  AWS analogue to Azure Chaos Studio).
- **Route 53 health checks + failover routing** — the standard multi-region failover
  mechanism, DNS-based (closer in role to Azure Traffic Manager than to Front Door).
- **Multi-AZ** is the default production baseline (RDS Multi-AZ, ALB across AZs, EC2
  Auto Scaling Groups spanning AZs) given the ≥3-AZ-per-region guarantee.
- Multi-region active-active topology typically combines Route 53 or Global Accelerator
  for routing, regional stacks behind each, and a multi-region-write-capable data layer
  (DynamoDB global tables, or an application-tier write-routing strategy if using
  Aurora).

## Well-Architected Framework (AWS's named pillar set)

AWS Well-Architected has **6 pillars**: Operational Excellence, Security, Reliability,
Performance Efficiency, Cost Optimization, and **Sustainability** (the pillar Azure's
and GCP's frameworks don't name explicitly in the same way). Use `architecture-
principles.md`'s neutral quality-pillar framing when reasoning across providers; use
these exact 6 when scoring an AWS-specific design against AWS's own framework.

## Known AWS-Specific Traps

- IAM is not "AWS's identity provider" in the Entra ID sense — it's the permissions
  layer; workforce SSO is a separate product (IAM Identity Center).
- Fargate is a launch type for ECS and EKS, not a third rung on a compute ladder
  parallel to "ECS vs EKS."
- Multi-region write support depends entirely on the specific data service chosen
  (DynamoDB global tables vs. Aurora Global Database behave very differently) — there is
  no single "AWS relational database can/can't do multi-region writes" answer.
- Not every AWS service is available in every region — check regional availability
  explicitly, especially for newer services (e.g., some Bedrock models, certain instance
  types).

> Source: AWS Well-Architected Framework and AWS service documentation
> (<https://aws.amazon.com/architecture/well-architected/>,
> <https://docs.aws.amazon.com/>). Verify current limits, pricing, and regional
> availability against AWS documentation — this reference is a working guide, not a
> pricing or SLA authority.
