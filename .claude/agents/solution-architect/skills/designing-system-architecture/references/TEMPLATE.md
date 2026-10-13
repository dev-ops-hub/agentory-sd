# <System name>: Architecture Design

**Status:** draft | ready  **Sources:** <brief / PRD path and sections / codebase paths / constitution version>  **Target platform:** <AWS / Azure / GCP / on-prem / hybrid>

## 0. Summary (REQUIRED)

Three to six lines for an executive reader: the recommended option, the headline cost with its range, and the one or two assumptions that move it most (by `A<k>`).

## 1. Requirements and NFR baseline (REQUIRED)

### Assumptions

| ID | Assumption | Why it matters | Basis |
|---|---|---|---|
| A1 | | | brief / PRD §x / industry norm (name it) |

### NFRs

| Area | Target | Basis |
|---|---|---|
| Throughput (RPS, peak and average) | | |
| Latency (p95 / p99 per critical path) | | |
| Availability (SLA / SLO) | | |
| Data durability and consistency | | |
| Compliance / residency | | |

Basis is one of: `brief`, `PRD §x`, `<source>, retrieved <date>`, `ASSUMPTION A<k>`.

## 2. High-level architecture (REQUIRED)

One paragraph naming the architecture style and why it fits the NFRs.

```mermaid
flowchart LR
    %% C4 context: users, the system, external systems
```

```mermaid
flowchart TB
    %% C4 container view: deployable units, data stores, messaging, trust boundaries as subgraphs
```

### 2.3 Network and subnet topology (REQUIRED for any cloud or on-prem target)

The most detailed diagram in the design. Nest `subgraph` blocks from the outside in: cloud / account or subscription / region → VPC or VNet (with CIDR) → availability zone → subnet (with CIDR and tier: public, private-app, private-data, management) → resource. Show every resource from section 3.1 inside the subnet it runs in, and every edge a traffic flow from section 4.2 (label it with its flow ID, protocol and port). Include the internet edge, load balancers, NAT or egress, gateways and endpoints, peering or VPN links, and the security-group or firewall boundary of each tier. Show at least two zones when the availability target needs it.

```mermaid
flowchart TB
    %% nested subgraphs: region > VPC <cidr> > AZ > subnet <cidr, tier> > resources
    %% edges labelled F1 HTTPS 443, F2 TCP 5432, ...
```

If the target is a single host or a local container (no cloud), draw the equivalent: host, container network, published ports, volumes and bind mounts, and the loopback boundary. Say so in one line.

## 3. Core component breakdown (REQUIRED)

| Component | Choice | Why (NFR or principle it serves) | Alternative | Framework reference |
|---|---|---|---|---|
| API gateway / edge | | | | WAF pillar or pattern name |
| Compute | | | | |
| Storage | | | | |
| Caching | | | | |
| Messaging | | | | |

### 3.1 Cloud resource inventory (REQUIRED)

One row per resource that will be created. Every resource in the section 2.3 diagram appears here and the reverse. Names are a convention (`<system>-<env>-<role>`), sizes come from the NFR baseline.

| # | Resource | Service / SKU | Region / zone | Network placement (VPC, subnet, CIDR) | Size and count | Scaling and HA | IaC module | Basis |
|---|---|---|---|---|---|---|---|---|
| R1 | | | | | | | | `ASSUMPTION A<k>` or source |

Cover: networking (VPC/VNet, subnets, route tables, gateways, NAT, endpoints, DNS, load balancers, WAF/CDN), compute, storage and databases, messaging, identity (roles, service accounts, key management), secrets, observability (logs, metrics, alerts), backup, and CI/CD.

### 3.2 Software architecture (REQUIRED)

How the code is organised on top of the infrastructure.

- **Layers and modules:** the layering rule (who may call whom) and the module list with each module's single responsibility and public interface.
- **Services and boundaries:** for each deployable unit: what it owns, its API (style, versioning, error convention), its data store, sync or async calls in and out.
- **Data model:** the entities, owners and the consistency rule between them.
- **Cross-cutting:** configuration, secrets, logging, error handling, retries and timeouts, idempotency, transactions.
- **Tech stack:** language, framework, libraries, with versions and the constitution rule or NFR each serves.

```mermaid
flowchart TB
    %% component view: layers, modules, dependency direction
```

## 4. Data flow and security architecture (REQUIRED)

```mermaid
sequenceDiagram
    %% the critical path, e.g. the write path that must never lose or duplicate data
```

| Layer | Control |
|---|---|
| Identity and access (least privilege) | |
| Service to service (mTLS / workload identity) | |
| Network (zero trust, segmentation) | |
| Secrets | |
| Data (encryption, classification) | |
| Detection and audit | |

### 4.2 Network traffic (REQUIRED)

One row per flow. Every edge in the section 2.3 diagram carries one of these IDs. Anything not listed is denied.

| Flow | From (resource, subnet) | To (resource, subnet) | Protocol and port | Direction | Encryption | Auth | Allowed by (security group / NACL / firewall rule) | Peak volume | Basis |
|---|---|---|---|---|---|---|---|---|---|
| F1 | | | | | | | | | `ASSUMPTION A<k>` or source |

Cover north-south (internet in, egress out), east-west (service to service, service to data), management and admin access, and observability and backup traffic. Add the estimated monthly egress per path where the cost depends on it.

## 5. Resilience and disaster recovery (REQUIRED)

| Failure | Design response | RTO | RPO |
|---|---|---|---|
| Instance / zone loss | | | |
| Dependency outage | | | |
| Region loss | | | |
| Data corruption / bad deploy | | | |

## 6. Trade-off matrix and cost (REQUIRED)

| Criterion | Option A (recommended) | Option B | Option C |
|---|---|---|---|
| Cost / month | | | |
| Latency | | | |
| Operational complexity | | | |
| Scaling path | | | |
| Lock-in | | | |
| Best when | | | |

### Cost of the recommended option

| Item | Sizing | Estimate / month | Basis |
|---|---|---|---|
| | | | `<pricing page>, retrieved <date>` or `ASSUMPTION A<k>: <size, region, tier>` |
| **Total** | | | |

## 7. Decisions (REQUIRED)

One ADR per decision that is costly to reverse, in the `develop-adr` Nygard shape (Title, Status `Proposed`, Context, Decision, Consequences). Number them `ADR-1`, `ADR-2`.

## 8. Gaps (REQUIRED)

- **Q1** [PM] <question about the product: scope, priority, NFR target, user behaviour> — impact: <what changes in cost, scope or targets, by roughly how much> — assumed meanwhile: A<k>
- **Q2** [USER] <question only the user or client can answer: budget, cloud account, compliance, existing infrastructure> — impact: … — assumed meanwhile: A<k>
- **C1** CONFLICT <source> says X, <source> says Y — options: … (only when sources disagree)

Tag each question `[PM]` or `[USER]` per the clarification protocol in the agent definition. Write `None` only when every assumption in section 1 is confirmed.
