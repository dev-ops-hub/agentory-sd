# GCP Implementation Reference

GCP-specific services, identity model, networking model, and Architecture Framework.
Read `architecture-principles.md`, `design-patterns.md`, `security.md`, and
`decision-frameworks.md` for the provider-neutral reasoning this file plugs into.

---

## Identity

GCP splits identity into users/groups and workload identity, with its own federation
mechanism — again, no clean 1:1 mapping to Entra ID or AWS IAM:

- **Cloud IAM** — role-based access control for users, groups, and service accounts.
  Prefer **predefined roles** (e.g. `roles/storage.objectViewer`); use **custom roles**
  only when predefined doesn't fit; avoid **basic roles** (`owner`/`editor`/`viewer`) in
  production — they're too broad.
- **Service Accounts (SA)** — the workload identity primitive. A **Service Account
  key** is a static credential and should be avoided in modern setups.
- **Workload Identity Federation** — the modern way to let non-GCP workloads (AWS,
  Azure, GitHub Actions, any OIDC provider) authenticate to GCP without a key: exchange
  an external OIDC token for a short-lived GCP access token via STS.
- **Workload Identity (GKE)** — maps Kubernetes service accounts to Google service
  accounts; eliminates key-mounting in pods specifically for GKE workloads.
- **Secret Manager** — secrets storage, with rotation support and IAM at the
  secret level, not just the project level.
- Bind IAM at the smallest workable scope: resource > project > folder > organization.

### Choosing identity (decision shape)
```
Workload running on GCP calling other GCP services?
├── On GKE → GKE Workload Identity (KSA → GSA)
├── On Cloud Run / Functions → built-in service identity
├── On Compute Engine → instance service account
└── In CI/CD outside GCP → Workload Identity Federation (no keys)

Workload outside GCP needing GCP access?
├── From AWS / Azure / any OIDC provider → Workload Identity Federation
└── Last resort → Service Account key (rotate frequently)
```

## Networking

**A GCP VPC is global by default** — subnets are regional, but routing is global. This
is a structural difference from Azure VNet and AWS VPC, both of which are regional
resources; it changes default multi-region topology, not just terminology (see Do Not
Assume in SKILL.md).

- **Global External Application Load Balancer** — global anycast HTTP(S), Cloud Armor
  + CDN integration, supports serverless backends.
- **Regional External Application Load Balancer** — single region, lower cost.
- **Internal Application Load Balancer** — internal HTTP(S), supports serverless
  backends via a Serverless NEG.
- **External Proxy Network Load Balancer** — global L4 proxy for TCP/SSL passthrough.
- **External / Internal Passthrough Network Load Balancer** — regional L4.
- **Cloud Armor** — WAF + DDoS protection at the edge in front of the global HTTP(S)
  load balancer. Standard tier (free, L3/L4 DDoS) vs. Plus/Enterprise (adaptive
  protection, custom rules, OWASP CRS preconfigured rule sets).
- **Private Service Connect (PSC)** — brings GCP-managed services (and partner
  services) into your VPC via private IP, without VPC peering or public exposure. The
  default pattern for production access to managed services (Cloud SQL, Memorystore,
  etc.).
- **Shared VPC** — a host project owns the VPC; service projects attach resources to
  it; the standard enterprise/multi-team pattern.
- **VPC peering** — connects two VPCs; routing is not transitive.
- **Network Connectivity Center** — hub-and-spoke routing for large multi-VPC
  organizations.
- The **default network** created in every new project should be deleted for production
  — create an explicit custom VPC with intentional subnets instead.

## Compute

| Service | Best For | Scale | Complexity |
|---|---|---|---|
| Compute Engine (GCE) | Full VM control, specialized hardware, legacy/compliance-bound apps | Managed Instance Groups (MIGs) for autoscale | High |
| GKE Autopilot | Managed Kubernetes, pay-per-pod, minimal ops | Up to ~1,000 nodes | Medium (ops), Low (day-to-day) |
| GKE Standard | Full Kubernetes control (custom nodes, GPUs, DaemonSets) | Up to ~15,000 nodes | High |
| Cloud Run | Serverless containers, HTTP- or event-driven, scale-to-zero | Automatic | Low |
| Cloud Functions (2nd gen) | Event-driven functions (runs on Cloud Run under the hood) | Automatic | Very Low |
| Batch | Managed batch/HPC compute pools | Autoscale on queue depth | Medium |

**Quick decision:**
- Full OS control / specialized hardware? → **Compute Engine** (in Managed Instance
  Groups for HA)
- Containers, want zero infra, scale-to-zero acceptable? → **Cloud Run**
- Always-warm container, still want minimal ops? → **Cloud Run with min-instances**, or
  **GKE Autopilot**
- Function-style, event-driven? → **Cloud Functions (2nd gen)**
- Full Kubernetes API/ecosystem, custom nodes/GPUs/DaemonSets? → **GKE Standard**
- Managed Kubernetes without node management? → **GKE Autopilot**
- Batch/HPC job processing? → **Batch**, or **Dataflow** for data-centric pipelines

GKE Autopilot bills per-Pod (CPU/memory requested); GKE Standard bills per-node VM plus
a cluster management fee. Autopilot is typically cheaper for sparse/variable workloads;
Standard is typically cheaper for dense, high-utilization clusters.

## Storage

| Storage class | Access cost | Storage cost | Min retention |
|---|---|---|---|
| Standard | Lowest | Highest | None |
| Nearline | Higher | ~50% off Standard | 30 days |
| Coldline | Higher still | ~80% off Standard | 90 days |
| Archive | Highest retrieval cost | ~95% off Standard | 365 days |

Cloud Storage is the object storage service; use Object Lifecycle Management for
automatic tiering/deletion, bucket-level IAM (not legacy ACLs), and Signed URLs for
time-limited public access instead of making a bucket public.

## Databases

| Service | Best For | Consistency | Scale |
|---|---|---|---|
| Cloud SQL (MySQL/PostgreSQL/SQL Server) | Standard OLTP, regional or multi-zone | Strong (ACID) | Up to 64TB (Enterprise) / 128TB (Enterprise Plus) |
| Cloud Spanner | Global strong consistency at horizontal scale, mission-critical OLTP | Strong, externally consistent | Virtually unlimited horizontal, multi-region |
| Firestore | Document DB, mobile/web client-direct, real-time updates | Strong within a document, tunable elsewhere | Multi-region option for HA |
| Bigtable | Wide-column at massive scale, sub-10ms reads, time-series/IoT | Eventual/tunable via replication | Petabyte-scale |
| BigQuery | Serverless analytical data warehouse | N/A (analytics) | Petabyte-scale |
| Memorystore (Redis/Memcached) | In-memory cache | N/A (cache) | Standard tier adds HA/replica |

**Cloud Spanner natively supports strongly-consistent multi-region active-active
writes** — this is a genuine capability most relational databases on other providers
don't match (Azure SQL is active-passive only; AWS Aurora Global Database replicates
from a single primary region). Don't assume every provider's "scale-out relational
database" story is equivalent — Spanner's multi-region write consistency is a specific,
real differentiator, not marketing parity.

Cloud SQL does not natively support multi-region writes; use regional/multi-zone HA and
read replicas, and move to Spanner specifically when multi-region strongly-consistent
writes or scale beyond Cloud SQL's ceiling is a hard requirement.

## Messaging / Integration

| Service | Best For |
|---|---|
| Pub/Sub | Global, fully managed pub/sub messaging and event ingestion |
| Eventarc | Event-driven triggers across GCP services (feeds Cloud Run, Cloud Functions) |
| Cloud Tasks | Managed asynchronous task queue with rate control |
| Dataflow | Managed Apache Beam batch/stream data processing |

## API Management

- **Apigee** — full API management (gateway, developer portal, monetization, rate
  limiting) — the GCP service closest in scope to Azure API Management.
- **API Gateway** (lighter-weight, serverless-backend-focused) for simpler
  request-routing/auth needs without Apigee's full feature set.

## AI/ML

| Service | Best For |
|---|---|
| Vertex AI | Managed ML platform: training, tuning, MLOps, online/batch prediction |
| Vertex AI (Model Garden) | Access to foundation models (Gemini and others) via a managed API |

## Observability

- **Cloud Logging** — centralized logs; first 50 GB/project/month free, then billed per
  GB ingested; route to BigQuery for cheaper long-term retention than Logging's own
  storage.
- **Cloud Monitoring** — metrics, uptime checks, SLO objects and burn-rate alerting.
- **Cloud Trace** — distributed tracing.
- **Cloud Profiler** — continuous production CPU/memory profiling.
- **Security Command Center (SCC)** — Standard (basic findings) vs. Premium (threat
  detection, container/VM scanning, compliance dashboards for CIS/ISO 27001/PCI-DSS).

## Infrastructure as Code / CI-CD

- **Terraform** is the de facto default IaC tool for GCP (Google also offers Config
  Connector for Kubernetes-native resource management, and Deployment Manager, which is
  legacy).
- **Cloud Build**, or GitHub Actions, for CI/CD.

## Governance / Cost

- **Recommender** — the GCP analogue to Azure Advisor / AWS Trusted Advisor
  (right-sizing, idle resource, IAM least-privilege recommendations).
- **Organization Policy** — governance guardrails (allowed regions, allowed services,
  disallow public IPs, require Shielded VMs, etc.) at org/folder/project scope.
- Common pricing gotchas: egress is charged (ingress is free); inter-region and
  inter-zone traffic within GCP is charged; BigQuery on-demand bills per byte scanned
  (partition and cluster tables to control this); static external IPs cost whether
  attached or not.

## Resilience / HA / DR

- Zonal and regional resource distinction matters: prefer **regional** managed services
  (Cloud SQL regional HA, regional MIGs) over zonal where available.
- No single named "Chaos Studio"-equivalent product; chaos engineering on GCP is
  typically done with open-source tooling (e.g., Chaos Mesh on GKE) rather than a
  first-party managed fault-injection service.
- Multi-region active-active topology: Global External Application Load Balancer for
  routing, regional deployment units behind it, Spanner (if the data layer needs
  multi-region strongly-consistent writes) or a replicated/eventually-consistent store
  otherwise.

## Google Cloud Architecture Framework (GCP's named pillar set)

The Google Cloud Architecture Framework has its own 5 pillars (Operational Excellence;
Security, Privacy & Compliance; Reliability; Cost Optimization; Performance
Optimization) — similar in spirit to, but not identically worded or scoped as, Azure's
WAF or AWS Well-Architected. Use `architecture-principles.md`'s neutral quality-pillar
framing when reasoning across providers; use GCP's own 5 when scoring a GCP-specific
design against GCP's own framework.

## Known GCP-Specific Traps

- A GCP VPC is global; an Azure VNet and an AWS VPC are both regional. Multi-region
  network design starts from a different default on GCP than on the other two.
- GCP's default service account (created automatically per project) is historically
  over-privileged — a well-documented trap specific to GCP; always create and bind
  scoped service accounts explicitly rather than using the default.
- Cloud Spanner's multi-region active-active write consistency is real and
  differentiating — don't undersell it by assuming it behaves like Azure SQL or Aurora
  Global Database just because all three are "cloud relational databases."
- Not every service is available in every region, and GKE Autopilot/Standard cost
  comparisons depend heavily on actual cluster utilization — verify before assuming one
  is cheaper by default.

> Source: Google Cloud Architecture Framework and Google Cloud documentation
> (<https://cloud.google.com/architecture/framework>, <https://cloud.google.com/docs>).
> Verify current limits, pricing, and regional availability against Google Cloud
> documentation — this reference is a working guide, not a pricing or SLA authority.
