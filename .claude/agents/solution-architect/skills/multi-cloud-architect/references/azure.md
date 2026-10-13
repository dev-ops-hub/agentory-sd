# Azure Implementation Reference

Azure-specific services, identity model, networking model, and well-architected
framework. Read `architecture-principles.md`, `design-patterns.md`, `security.md`, and
`decision-frameworks.md` for the provider-neutral reasoning this file plugs into.

---

## Identity

**Microsoft Entra ID** (formerly Azure AD) is Azure's single identity platform for
users, applications, and service-to-service authentication — this unified scope is an
Azure-specific property; don't assume AWS or GCP have one identity product that covers
both humans and workloads the same way (see SKILL.md's Do Not Assume list).

- **Azure Managed Identities** — credential-free service-to-service auth; the default
  for any Azure resource calling another Azure service.
- **Azure Key Vault** — secrets, certificates, and key management.
- **Microsoft Entra External ID** — customer/partner identity (B2C/B2B scenarios).
- **Microsoft Entra PIM** — Just-In-Time and Just-Enough-Access privileged role
  activation.
- Federation protocols supported: SAML, OIDC, OAuth 2.0.

## Networking

- **Azure Virtual Network (VNet) is a regional resource.** Subnets live inside a VNet;
  use subnets plus NSGs to segment tiers and control traffic flow (standard for N-tier).
- **Azure Front Door** — global HTTP(S) load balancing, CDN, WAF, SSL offload; Layer 7,
  global scope.
- **Application Gateway** — regional HTTP(S) load balancing with WAF; Layer 7, regional
  scope.
- **Azure Load Balancer** — TCP/UDP traffic distribution; Layer 4, regional, zone
  redundant.
- **Traffic Manager** — DNS-based global routing (failover, performance, geographic).
- **Azure Private Link** — private connectivity to PaaS services without traversing the
  public internet.
- **Azure DDoS Protection** — standard tier for public-facing endpoints at scale.

### Quick decision — load balancing
- Global HTTP(S) with CDN and WAF? → **Front Door**
- Regional HTTP(S) with WAF? → **Application Gateway**
- Regional TCP/UDP load balancing? → **Load Balancer**
- DNS-based global failover? → **Traffic Manager**

## Compute

| Service | Best For | Scale | Complexity | Cost Model |
|---|---|---|---|---|
| Azure VMs | Full control, lift-and-shift, custom OS | Manual/VMSS | High | Per-hour |
| App Service | Web apps, APIs, mobile backends | Built-in autoscale | Low | Per App Service plan |
| Azure Functions | Event-driven, short-lived processes | Consumption-based auto | Very Low | Per execution |
| AKS | Microservices, complex orchestration | Node/pod autoscaling | High | Per node VM |
| Container Apps | Serverless containers, microservices | KEDA-based autoscale | Medium | Per vCPU/memory/s |
| Container Instances | Simple containers, batch jobs | Per-instance | Very Low | Per second |

**Quick decision:**
- Need full OS control? → **VMs**
- Web app/API with minimal ops? → **App Service**
- Short-lived event-driven code? → **Functions**
- Complex microservices with K8s expertise? → **AKS**
- Microservices without K8s management? → **Container Apps**
- Run a container quickly, no orchestration? → **Container Instances**

The managed-service substitution ladder below is Azure-specific — don't assume it maps
service-for-service onto AWS or GCP's equivalent ladder:

| IaaS | PaaS Alternative |
|------|-------------------|
| VMs with IIS/Nginx | Azure App Service |
| VMs with SQL Server | Azure SQL Database |
| VMs with RabbitMQ | Azure Service Bus |
| VMs with Kubernetes | Azure Kubernetes Service (AKS) |
| VMs with custom functions | Azure Functions |
| VMs with Redis | Azure Cache for Redis |
| VMs with Elasticsearch | Azure AI Search |

## Containers

| Service | Best For | Orchestration | Complexity | Cost |
|---|---|---|---|---|
| AKS | Full Kubernetes, complex workloads | Full K8s control plane | High | Per node VM |
| Container Apps | Serverless containers, event-driven | Managed (built on K8s) | Medium | Per vCPU/memory/s |
| Container Instances | Simple containers, sidecar groups, batch | None (per-instance) | Very Low | Per second |

AKS supports availability-zone-redundant node pools; prioritize zone redundancy for
production workloads and avoid mixing zonal and non-zonal services within a scale unit.

## Storage

| Service | Best For | Access Pattern | Scale | Cost |
|---|---|---|---|---|
| Blob Storage | Unstructured data, media, backups | REST API, SDK | Massive | Per GB + operations |
| Azure Files | SMB/NFS file shares, lift-and-shift | File system mount | TB-scale | Per GB provisioned |
| Queue Storage | Simple message queuing | Pull-based | High throughput | Very low per message |
| Table Storage | NoSQL key-value data | REST API | TB-scale | Per GB + operations |
| Data Lake Storage | Big data analytics, hierarchical namespace | ABFS, REST | Massive | Per GB, tiered |

## Databases

| Service | Best For | Consistency | Scale | Cost Model |
|---|---|---|---|---|
| Azure SQL | Relational, OLTP, enterprise apps | Strong (ACID) | Up to Hyperscale | DTU or vCore-based |
| Cosmos DB | Global distribution, multi-model, low latency | Tunable (5 levels) | Unlimited horizontal | RU/s + storage |
| Azure Database for PostgreSQL | Open-source relational, PostGIS, JSON | Strong (ACID) | Flexible Server auto | vCore-based |
| Azure Database for MySQL | Open-source relational, web apps | Strong (ACID) | Flexible Server auto | vCore-based |

**Azure SQL does not natively support active-active concurrent writes across regions.**
Use active-passive: single primary region for writes, read replicas elsewhere, with
auto-failover groups for automated regional failover. Partial active-active is possible
at the application tier (route reads locally, writes to primary). This is an Azure SQL
limitation specifically — don't generalize it to "relational databases can't do
multi-region writes" when reasoning about other providers.

**Cosmos DB** supports true multi-region active-active writes with 5 tunable consistency
levels (strong to eventual) — the natural choice when mission-critical workloads need
global write availability.

## Messaging

| Service | Best For | Delivery | Throughput | Cost |
|---|---|---|---|---|
| Service Bus | Enterprise messaging, ordered delivery, transactions | At-least-once / at-most-once | Moderate-high | Per operation + unit |
| Event Hubs | Event streaming, telemetry, big data ingestion | At-least-once, partitioned | Very high (millions/s) | Per TU/PU + ingress |
| Event Grid | Event-driven reactive programming, webhooks | At-least-once | High | Per operation |
| Queue Storage | Simple async messaging, decoupling | At-least-once | Moderate | Very low per message |

## AI Services

| Service | Best For | Complexity |
|---|---|---|
| Azure OpenAI | LLMs, GPT models, generative AI | Medium |
| Azure AI Services | Pre-built vision/speech/language | Low |
| Azure Machine Learning | Custom ML, MLOps, training | High |

## Observability

- **Azure Monitor** — metrics, logs, alerts across all Azure resources.
- **Application Insights** — APM and distributed tracing.
- **Azure Log Analytics** — centralized log querying with KQL.

## Infrastructure as Code / CI-CD

- **Bicep / Azure Resource Manager (ARM) templates** — native IaC.
- **Azure DevOps Pipelines / GitHub Actions** — CI/CD.

## Governance / Cost

- **Azure Advisor** — cost, performance, reliability, security recommendations.
- **Azure Cost Management** — budget tracking and cost optimization.
- **Azure Service Health** — SLA tracking and incident awareness.
- **Azure Policy** — governance guardrails (allowed regions, allowed SKUs, tagging
  enforcement).

## Resilience / Chaos / HA

- **Azure Chaos Studio** — fault injection and chaos experiments.
- **Availability Zones** — not available in every region; verify before assuming zonal
  redundancy is available for a target region.
- **Azure Site Recovery** — disaster recovery orchestration.
- Mission-critical topology: active-active across 2+ regions via **Azure Front Door**
  for global routing, deployment stamps per region, **Cosmos DB** multi-region writes or
  **Azure SQL** active-passive with auto-failover groups depending on the data layer
  chosen, zone-redundant configuration for every stateful service in a stamp.

## Well-Architected Framework (Azure's named pillar set)

Azure's Well-Architected Framework (WAF) has **5 pillars**: Reliability, Security, Cost
Optimization, Operational Excellence, Performance Efficiency. Use `architecture-
principles.md`'s neutral quality-pillar framing when reasoning across providers; use
these exact 5 when scoring an Azure-specific design against Azure's own framework.

## Known Azure-Specific Traps

- Entra ID is not "Azure's IAM" in the AWS/GCP sense — it's broader (unified human +
  workload identity). Mapping it 1:1 to AWS IAM or GCP IAM understates its scope.
- VNets are regional. Multi-region network topology requires explicit VNet peering or a
  hub-and-spoke design across regions — it does not "just work" the way a GCP global VPC
  does.
- Not every region has Availability Zones. Verify zone support for the target region
  before designing a zone-redundant architecture around it.
- Azure SQL's active-passive-only multi-region write limitation is specific to that
  service; Cosmos DB in the same cloud does not share that limitation.

> Source: Azure Architecture Center (<https://learn.microsoft.com/en-us/azure/architecture/>).
> Verify current limits, pricing, and regional availability against Microsoft Learn —
> this reference is a working guide, not a pricing or SLA authority.
