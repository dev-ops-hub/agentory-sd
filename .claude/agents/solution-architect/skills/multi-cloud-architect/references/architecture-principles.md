# Provider-Neutral Architecture Principles

These principles, styles, best practices, and antipatterns apply the same way on Azure,
AWS, and GCP. For the service that implements a tactic on a specific provider, see that
provider's reference file.

---

## Ten Design Principles

| # | Principle | Key Tactics |
|---|-----------|-------------|
| 1 | **Design for self-healing** | Retry with backoff, circuit breaker, bulkhead isolation, health endpoint monitoring, graceful degradation, chaos engineering |
| 2 | **Make all things redundant** | Eliminate single points of failure, use availability zones, deploy multi-region, replicate data, define RTO/RPO |
| 3 | **Minimize coordination** | Decouple services, use async messaging, embrace eventual consistency, use domain events, idempotent operations |
| 4 | **Design to scale out** | Horizontal scaling, autoscaling on live metrics, stateless services, avoid session stickiness, partition workloads |
| 5 | **Partition around limits** | Data partitioning (shard/hash/range), respect compute & network service limits, use a CDN for static content |
| 6 | **Design for operations** | Structured logging, distributed tracing, metrics & dashboards, runbook automation, infrastructure as code |
| 7 | **Use managed services** | Prefer platform-managed compute/data/messaging over self-managed infrastructure; reduce operational burden |
| 8 | **Use an identity service** | Centralize identity, prefer workload identity over long-lived credentials, RBAC, zero-trust principles |
| 9 | **Design for evolution** | Loose coupling, versioned APIs, backward compatibility, async messaging for integration, feature flags |
| 10 | **Build for business needs** | Define SLAs/SLOs, establish RTO/RPO targets, domain-driven design, cost modeling, composite SLAs |

Each principle's provider-specific tactics and services are in that provider's
reference file (`azure.md`, `aws.md`, `gcp.md`).

### Composite availability

For N redundant instances each with availability A, composite availability is
`1 - (1 - A)^N`. Use this to justify (or question) a redundancy decision with a number,
not a feeling.

---

## Architecture Styles

| Style | Description | When to Use |
|-------|-------------|-------------|
| **N-tier** | Horizontal layers (presentation, business, data) | Traditional enterprise apps, lift-and-shift, low update frequency |
| **Web-Queue-Worker** | Web frontend → message queue → backend worker | Moderate-complexity apps with long-running or resource-intensive tasks |
| **Microservices** | Small autonomous services, bounded contexts, independent deploy | Complex domains, independent team scaling, frequent updates |
| **Event-driven** | Pub/sub or event-streaming; producers/consumers decoupled | Real-time processing, IoT, reactive systems |
| **Big data** | Batch + stream processing pipeline over a data lake | Analytics, ML pipelines, large-scale data |
| **Big compute** | HPC, massively parallel processing | Simulations, modeling, rendering, genomics, financial risk |

### Selection Criteria

- **Domain complexity** → Microservices (high), N-tier (low-medium)
- **Team autonomy** → Microservices (independent teams), N-tier (single team)
- **Data volume** → Big data (TB+), others (GB)
- **Latency requirements** → Event-driven (real-time), Web-Queue-Worker (latency-tolerant)

### Style Details

#### N-tier
Each layer communicates only with the layer directly below it (presentation → business
logic → data access). Benefits: familiar, natural fit for migrating existing layered
apps, clear separation of concerns. Challenges: horizontal layering makes cross-cutting
changes touch every tier; tiers are coupled vertically, limiting release velocity. Keep
each tier stateless where possible; isolate tiers with network segmentation (subnets,
security groups/NSGs/firewall rules).

#### Web-Queue-Worker
A web frontend handles requests; a worker performs resource-intensive or long-running
work; the two communicate only through an async queue. Benefits: easy to deploy, clean
separation of interactive vs. background work, independent scaling. Challenges: without
discipline the two sides become monolithic; hidden coupling emerges if they share a
schema. Keep the frontend thin, use durable queues, design idempotent workers.

#### Microservices
Autonomous services, each owning a bounded context and its own data, communicating via
well-defined APIs. Benefits: independent team velocity, technology diversity, frequent
releases. Challenges: service discovery and inter-service communication add complexity;
cross-service consistency needs Saga or eventual consistency; distributed tracing becomes
mandatory, not optional. Avoid sharing a database between services; put an API gateway in
front for cross-cutting concerns; build in health checks and circuit breakers from day one.

#### Event-driven
Producers emit events; consumers react, fully decoupled via a broker or event channel.
Two models: pub/sub (events delivered to subscribers) and event streaming (events written
to an ordered log for consumers to read at their own pace). Benefits: producers and
consumers evolve independently, highly scalable, well-suited to real-time pipelines.
Challenges: guaranteed delivery needs dead-letter handling; ordering is hard to maintain
across partitions; consumers see eventual consistency; poison messages need explicit
handling. Design events as immutable facts with clear, versioned schemas.

#### Big Data
Pipeline: data sources → data lake → batch and/or real-time processing → analytical data
store → analysis/reporting, with an orchestration layer coordinating the whole thing.
Benefits: handles datasets beyond traditional database capacity, supports both batch and
real-time analytics, enables ML at scale. Challenges: coordinating batch and real-time
paths is complex; a data lake needs disciplined schema and governance or it becomes a data
swamp; storage/compute cost can grow unpredictably. Partition data for parallel reads;
apply schema-on-read; process on arrival rather than waiting for batch windows.

#### Big Compute
A job scheduler distributes work across hundreds to thousands of cores, independent
("embarrassingly parallel") or tightly coupled with inter-node communication. Benefits:
massive parallel throughput, access to specialized hardware (GPU/accelerators), scales to
thousands of cores. Challenges: provisioning that many cores fast enough to meet a
deadline; idle compute is expensive; infrastructure management at scale. Use
spot/preemptible capacity for fault-tolerant workloads; autoscale on queue depth;
partition into independent tasks wherever possible.

---

## Twelve Cross-Cutting Best Practices

| Practice | Key Guidance |
|----------|--------------|
| **API design** | RESTful conventions, resource-oriented URIs (nouns not verbs), HATEOAS, versioning via URL path or header |
| **API implementation** | Idempotent PUT/DELETE, content negotiation, pagination, async for long operations (202 + polling), compress large payloads |
| **Autoscaling** | Scale on metrics that correlate with load (CPU, queue depth, custom), cooldown periods to prevent flapping, plan for scale-event latency |
| **Background jobs** | Trigger via queue/event/schedule, idempotent and checkpointed for safe restart, graceful shutdown, monitor job health explicitly |
| **Caching** | Cache-aside pattern, TTL policies balanced against freshness needs, invalidation strategy aligned to data change pattern, guard against cache stampede |
| **CDN** | Offload static assets, version URLs for cache-busting, enforce HTTPS, plan a fallback for CDN unavailability |
| **Data partitioning** | Choose partition keys that distribute load evenly, horizontal/vertical/functional partitioning by access pattern, minimize cross-partition queries |
| **Host name preservation** | Forward the original Host header through proxies/gateways so cookies, redirects, and CORS resolve against the external host, not an internal one |
| **Message encoding** | Choose JSON (interoperability) vs. compact binary (Avro/Protobuf/MessagePack) for throughput; validate against a versioned schema |
| **Monitoring & diagnostics** | Structured logs, distributed tracing with correlation IDs across services, actionable alerts (not noise), performance baselines |
| **Transient fault handling** | Retry with exponential backoff + jitter, circuit breaker to stop retrying persistent failures, distinguish transient (429/503) from permanent (400/404) errors, bound total retry time |
| **Observability instrumentation** | Instrument from day one: logs, metrics, traces; dashboards that surface actionable signal, not raw data |

---

## Ten Performance Antipatterns

Common patterns that degrade performance under load, independent of cloud provider:

| Antipattern | Problem | Fix |
|-------------|---------|-----|
| **Busy Database** | Offloading formatting/calculation logic into the data store | Move processing to the application tier; limit the database to data access and aggregation |
| **Busy Front End** | Resource-intensive work running on request-handling threads | Offload to background workers/queues |
| **Chatty I/O** | Many small I/O calls instead of fewer larger ones | Batch requests, use bulk APIs, buffer writes, cache |
| **Extraneous Fetching** | Retrieving more data than needed (`SELECT *`, full-table reads) | Project only required fields, paginate, filter server-side |
| **Improper Instantiation** | Recreating expensive objects (HTTP clients, DB connections) per request | Singletons, connection pooling, client factories |
| **Monolithic Persistence** | One data store for workloads with very different access patterns | Polyglot persistence — the right store per workload |
| **No Caching** | Repeatedly fetching unchanged data | Cache-aside pattern, CDN, output caching, in-memory/distributed cache |
| **Noisy Neighbor** | One tenant consuming a disproportionate share of shared resources | Bulkhead isolation, per-tenant quotas, throttling |
| **Retry Storm** | Aggressive, uncoordinated retries overwhelming a recovering service | Exponential backoff + jitter, circuit breaker, retry budgets |
| **Synchronous I/O** | Blocking threads on I/O that could be async | Async/await, non-blocking I/O, reactive streams |

---

## High Availability / Disaster Recovery Framework

A target SLO drives every HA/DR decision. Permitted annual downtime at common targets:

| SLO Target | Permitted Annual Downtime | Typical Use Case |
|---|---|---|
| 99.9% | 8 hours 45 minutes | Standard business apps |
| 99.95% | 4 hours 22 minutes | Important business apps |
| 99.99% | 52 minutes 35 seconds | Mission-critical workloads |
| 99.999% | 5 minutes 15 seconds | Safety-critical systems |

### Design strategies for mission-critical workloads (99.99%+)

1. **Redundancy in layers** — eliminate single points of failure at every layer; prefer
   active-active across 2+ regions where the data layer supports it (check the specific
   provider/service — see the Do Not Assume list in SKILL.md); use zonal redundancy for
   every stateful service in the design, never mix zonal and non-zonal components.
2. **Deployment stamps / scale units** — a self-contained, independently-scalable
   deployment unit with its own compute and local state, no durable system-of-record data
   stored locally (that lives only in the replicated database), no cross-stamp
   dependencies except shared global services. Enables regional fault isolation and
   stamp-level blue/green rollout.
3. **Reliable, repeatable deployments** — infrastructure as code with version control,
   zero-downtime blue/green or canary rollout, identical pipeline across environments,
   continuous validation (automated tests as part of the pipeline), synchronized load +
   chaos testing.
4. **Operational insight without a new single point of failure** — avoid a single
   centralized observability store as the only pane of glass; use federated/cross-queried
   observability; build a layered health model: component health scores → aggregated to
   user-flow health → mapped to a traffic-light status (green/yellow/red) → tied to
   automated action (alert, increase monitoring, trigger failover, block deploys).

### Health modeling

1. Identify critical user flows (login, checkout, search...).
2. Decompose each flow into the components it depends on.
3. Score each component's health from its own metrics (error rate, p95/p99 latency,
   saturation, data-freshness/replication lag).
4. Aggregate component scores, weighted by criticality, into a flow-level score.
5. Map the aggregate to green/yellow/red and a corresponding automated action.

### Zero-downtime (blue/green) deployment

Provision the new version alongside the old one → run automated validation against it →
route a small canary percentage of traffic → compare health scores between versions →
shift traffic in increments → decommission the old version only once the new one is fully
validated. Rollback = shift traffic back; the old version keeps running during validation,
not torn down immediately.

### Chaos engineering

Use the provider's fault-injection tooling (see provider reference) to test failure modes
— zone outage, network partition, dependency failure, resource pressure — ideally as part
of the CI/CD pipeline so every deployment is validated under fault conditions, and under
realistic load (synchronized load + chaos testing), not in isolation.

---

## Quality Pillars (provider-neutral framing)

Every cloud provider brands its own named framework around the same underlying set of
concerns. Use this neutral framing when reasoning across providers; use the provider's
own named pillar set (in that provider's reference file) when scoring a design built on
that specific provider, since the exact pillar count and wording differs by provider —
see the Do Not Assume list in SKILL.md.

| Quality Concern | Focus | Key Questions |
|---|---|---|
| **Reliability** | Resiliency, availability, disaster recovery | What is the RTO/RPO? How does it handle failures? Is there redundancy? |
| **Security** | Threat protection, identity, data protection | Is identity centrally managed? Is data encrypted? Are there network controls? |
| **Cost Optimization** | Cost management, efficiency, right-sizing | Is compute right-sized? Are commitments/reservations used where they pay off? Is there waste? |
| **Operational Excellence** | Monitoring, deployment, automation | Is deployment automated? Is there real observability? Are there runbooks? |
| **Performance Efficiency** | Scaling, load testing, performance targets | Can it scale horizontally? Are there performance baselines? Is caching used? |

### Tradeoff Matrix

| Optimizing for... | May impact... |
|-------------------|---------------|
| Reliability (redundancy) | Cost (more resources) |
| Security (isolation) | Performance (added latency) |
| Cost (consolidation) | Reliability (shared failure domains) |
| Performance (caching) | Cost (cache infrastructure), Reliability (stale data) |

---

> Generalized from the Azure Architecture Center's design principles, architecture
> styles, best practices, and performance antipatterns — the content in this file
> contains no provider-specific service names by design.
