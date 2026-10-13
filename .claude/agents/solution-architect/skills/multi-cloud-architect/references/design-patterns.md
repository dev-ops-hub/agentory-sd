# Cloud Design Patterns

A comprehensive reference of 44 cloud design patterns, organized by concern area and
detailed with problem context, usage scenarios, quality-pillar alignment, and related
patterns. These patterns are architectural concepts, not provider-specific — they apply
on Azure, AWS, and GCP alike. Pillar codes: **R**=Reliability, **S**=Security,
**CO**=Cost Optimization, **OE**=Operational Excellence, **PE**=Performance Efficiency.

---

## Patterns by Concern

### Availability / Reliability
Circuit Breaker · Compensating Transaction · Health Endpoint Monitoring · Leader Election
· Queue-Based Load Leveling · Retry · Saga · Scheduler Agent Supervisor · Sequential
Convoy · Bulkhead · Rate Limiting

### Data Management
Cache-Aside · CQRS · Event Sourcing · Index Table · Materialized View · Sharding · Valet
Key · Claim Check

### Design / Implementation
Ambassador · Anti-Corruption Layer · Backends for Frontends · Compute Resource
Consolidation · Deployment Stamps · External Configuration Store · Gateway Aggregation ·
Gateway Offloading · Gateway Routing · Sidecar · Strangler Fig · Federated Identity

### Messaging
Asynchronous Request-Reply · Choreography · Claim Check · Competing Consumers ·
Messaging Bridge · Pipes and Filters · Priority Queue · Publisher/Subscriber ·
Queue-Based Load Leveling · Sequential Convoy

### Performance / Scalability
Cache-Aside · Geode · Throttling · Deployment Stamps · CQRS

### Security
Gatekeeper · Quarantine · Valet Key · Federated Identity · Throttling

---

## Pattern Reference

### 1. Ambassador
**Create helper services that send network requests on behalf of a consumer service.**
**Problem:** Apps need common connectivity features (monitoring, logging, routing, TLS,
resiliency) that legacy or hard-to-modify apps may not support natively.
**When to use:** common client connectivity features across polyglot services; the
connectivity concern is owned by an infra team; reducing legacy networking complexity
without touching source.
**Pillars:** Reliability, Security. **Related:** Sidecar, Gateway Routing, Gateway
Offloading.

### 2. Anti-Corruption Layer
**A façade/adapter layer between a modern application and a legacy system.**
**Problem:** Migrations must integrate with a legacy data model/API without letting that
model leak into the new system's design.
**When to use:** multi-phase migration where old and new coexist; the new domain model
differs significantly from the legacy one; two bounded contexts need to talk without
contaminating each other.
**Pillars:** Operational Excellence. **Related:** Strangler Fig, Gateway Routing.

### 3. Asynchronous Request-Reply
**Decouple backend processing from a frontend host while still giving the frontend a
clear way to learn the result.**
**Problem:** The client expects acknowledgement immediately but work happens in the
background, and the client can't hold a long-lived connection or provide a callback.
**When to use:** backend work takes seconds to minutes; the client is browser-based with
no callback endpoint; you want HTTP + polling instead of WebSockets/SSE.
**Pillars:** Performance Efficiency. **Related:** Competing Consumers, Pipes and
Filters, Queue-Based Load Leveling.

### 4. Backends for Frontends
**Separate backend services per frontend type (mobile, web, desktop, IoT).**
**Problem:** A general-purpose backend accumulates conflicting requirements from
different frontends; it becomes bloated and a shared bottleneck.
**When to use:** different clients need different payload shapes/latency profiles;
frontend teams need independent release cycles.
**Pillars:** Reliability, Security, Performance Efficiency. **Related:** Gateway
Aggregation, Gateway Offloading, Gateway Routing.

### 5. Bulkhead
**Isolate elements into pools so a failure in one doesn't take down the others.**
**Problem:** A slow/unresponsive downstream can exhaust a shared thread/connection pool,
causing cascading failure in unrelated functionality.
**When to use:** protecting critical consumers from non-critical dependency failures; a
noisy tenant shouldn't degrade others; limiting blast radius.
**Pillars:** Reliability, Security, Performance Efficiency. **Related:** Circuit
Breaker, Retry, Throttling, Queue-Based Load Leveling.

### 6. Cache-Aside
**Load data on demand into a cache from a data store.**
**Problem:** Repeated reads of the same data increase latency and cost against the
primary store.
**When to use:** read-heavy access to data that tolerates brief staleness; the store has
no native caching; you want to cut cost and latency on repeated reads.
**Pillars:** Reliability, Performance Efficiency. **Related:** Materialized View, Event
Sourcing, CQRS.

### 7. Choreography
**Each component participates in workflow decisions instead of relying on a central
orchestrator.**
**Problem:** A central orchestrator can become a single point of failure, a bottleneck,
or a source of tight coupling.
**When to use:** independently-owned services; a workflow that changes often; avoiding a
single point of failure in coordination.
**Pillars:** Operational Excellence, Performance Efficiency. **Related:**
Publisher/Subscriber, Saga, Competing Consumers.

### 8. Circuit Breaker
**Stop calling a remote service that's failing; fail fast instead of waiting.**
**Problem:** Retry alone wastes resources when a dependency is down for an extended
period; continuing to call it also prevents it from recovering.
**When to use:** intermittent prolonged outages; you need to fail fast rather than block
callers; you want to give a failing dependency room to recover.
**Pillars:** Reliability, Performance Efficiency. **Related:** Retry, Bulkhead, Health
Endpoint Monitoring, Ambassador.

### 9. Claim Check
**Split a large message into a claim check (reference) and payload stored separately.**
**Problem:** Brokers have size limits and per-message cost; large payloads waste
bandwidth and may hit transport limits.
**When to use:** payload exceeds broker size limits; you want smaller/cheaper messages;
not every consumer needs the full payload.
**Pillars:** Reliability, Security, Cost Optimization, Performance Efficiency.
**Related:** Competing Consumers, Pipes and Filters, Publisher/Subscriber.

### 10. Compensating Transaction
**Undo the work of a multi-step operation when a later step fails.**
**Problem:** Distributed systems can't rely on ACID transactions across services; failed
later steps leave earlier, already-committed steps in place.
**When to use:** multi-step operations spanning services/stores with no shared
transaction coordinator; rollback is semantically meaningful (refund, release a hold).
**Pillars:** Reliability. **Related:** Saga, Retry, Scheduler Agent Supervisor.

### 11. Competing Consumers
**Multiple concurrent consumers process messages from the same channel.**
**Problem:** A single consumer can't keep up at peak load; messages queue and latency
grows.
**When to use:** variable workload needing dynamic scaling; independent, parallelizable
messages; high availability via multiple consumers.
**Pillars:** Reliability, Cost Optimization, Performance Efficiency. **Related:**
Queue-Based Load Leveling, Priority Queue, Publisher/Subscriber, Pipes and Filters.

### 12. Compute Resource Consolidation
**Combine multiple lightweight tasks into a single computational unit.**
**Problem:** Deploying each small task separately adds operational overhead for
underutilized components.
**When to use:** several low-usage processes with the same scaling profile/lifecycle;
reducing deployment overhead; in-process communication is cheaper than network calls.
**Pillars:** Cost Optimization, Operational Excellence, Performance Efficiency.
**Related:** Sidecar, Backends for Frontends.

### 13. CQRS (Command and Query Responsibility Segregation)
**Separate read and write models behind separate interfaces.**
**Problem:** A single CRUD model forces a compromise between a normalized write shape
and a denormalized, query-optimized read shape.
**When to use:** asymmetric read/write load; different schema needs per side;
independent scaling of reads vs. writes; event-driven domain style.
**Pillars:** Performance Efficiency. **Related:** Event Sourcing, Materialized View,
Cache-Aside.

### 14. Deployment Stamps
**Deploy multiple independent copies of application components, including data stores.**
**Problem:** A single shared deployment couples tenants/regions; a fault in one affects
all; data residency rules may require isolation; scaling for one tenant's spike wastes
resources for everyone else.
**When to use:** tenant isolation for compliance/performance/fault isolation; multi-region
data residency; independent per-tenant/region scaling; stamp-level blue/green or canary.
**Pillars:** Operational Excellence, Performance Efficiency. **Related:** Geode,
Sharding, Throttling.

### 15. Edge Workload Configuration
**Centrally configure workloads running on heterogeneous edge devices.**
**Problem:** Numerous, intermittently-connected edge devices drift in configuration when
managed individually.
**When to use:** a fleet of edge devices with shared workload but differing local
parameters; need a central source of truth with local overrides; audit/compliance needs
per-device config tracking.
**Pillars:** Operational Excellence. **Related:** External Configuration Store, Sidecar,
Ambassador.

### 16. Event Sourcing
**Record state as an append-only sequence of events rather than mutable current state.**
**Problem:** Traditional CRUD only keeps current state; history is lost, making audit,
replay, and temporal queries hard without brittle supplementary logging.
**When to use:** full immutable audit trail required; replaying/projecting events into
different views; decoupling write model from read model (often with CQRS); regulatory
need to reconstruct past states.
**Pillars:** Reliability, Performance Efficiency. **Related:** CQRS, Materialized View,
Compensating Transaction, Saga.

### 17. External Configuration Store
**Move configuration out of the deployment package into a centralized location.**
**Problem:** Config baked into the deployment artifact requires a redeploy to change,
and sharing config across services duplicates it per service.
**When to use:** multiple services share settings; config must change without a
redeploy/restart; centralized audit/access control for config; config differs per
environment but is managed in one system.
**Pillars:** Operational Excellence. **Related:** Edge Workload Configuration, Sidecar.

### 18. Federated Identity
**Delegate authentication to an external identity provider.**
**Problem:** Building and operating your own identity store carries security risk
(password storage, rotation, MFA) and forces users to manage yet another credential.
**When to use:** users already have an identity in an enterprise directory or social
provider; you want SSO across apps; partners need access with their own credentials.
**Pillars:** Reliability, Security, Performance Efficiency. **Related:** Gatekeeper,
Valet Key, Gateway Offloading.

### 19. Gatekeeper
**Protect services with a dedicated broker host that validates requests before they
reach the trusted service.**
**Problem:** Public endpoints mixing validation/sanitization logic with business logic
increase the attack surface if the service is compromised.
**When to use:** sensitive data or high-value transactions; a centralized point for
request validation; an explicit security boundary required by compliance.
**Pillars:** Security. **Related:** Valet Key, Gateway Routing, Gateway Offloading,
Federated Identity.

### 20. Gateway Aggregation
**Aggregate multiple backend calls into a single client-facing request.**
**Problem:** A client needing data from several microservices makes many round-trips,
increasing latency and client complexity, and coupling the client to backend topology.
**When to use:** mobile/remote clients with significant network latency; reducing
chattiness; hiding backend topology from the client.
**Pillars:** Reliability, Security, Operational Excellence, Performance Efficiency.
**Related:** Backends for Frontends, Gateway Offloading, Gateway Routing.

### 21. Gateway Offloading
**Offload shared cross-cutting functionality (TLS, auth, rate limiting, logging) to a
gateway.**
**Problem:** Cross-cutting concerns duplicated per-service lead to inconsistency and
wasted effort.
**When to use:** multiple services share the same cross-cutting concerns; you want to
centralize instead of duplicate; the gateway is already in the request path.
**Pillars:** Reliability, Security, Cost Optimization, Operational Excellence,
Performance Efficiency. **Related:** Gateway Aggregation, Gateway Routing, Sidecar,
Ambassador.

### 22. Gateway Routing
**Route requests to multiple services behind a single endpoint.**
**Problem:** Clients that must know every service address are broken by any service
move/add/remove, and the internal topology leaks into client config.
**When to use:** path/header-based routing behind one URL; decoupling client URLs from
internal topology; versioned APIs or blue/green at the gateway.
**Pillars:** Reliability, Operational Excellence, Performance Efficiency. **Related:**
Gateway Aggregation, Gateway Offloading, Backends for Frontends.

### 23. Geode
**Deploy backend services into multiple geographic nodes, each able to serve any
client's request.**
**Problem:** Routing all global traffic to one region adds latency, creates a single
point of failure, and can't satisfy multi-jurisdiction data residency.
**When to use:** globally distributed users expecting low latency; active-active
multi-region availability; data residency/sovereignty constraints; a single-region
failure must not take the service down globally.
**Pillars:** Reliability, Performance Efficiency. **Related:** Deployment Stamps,
Sharding, Cache-Aside, Static Content Hosting.

### 24. Health Endpoint Monitoring
**Expose functional health checks that external tools can poll.**
**Problem:** Without health checks, failures surface only via user reports; load
balancers/orchestrators have no programmatic way to know an instance is healthy.
**When to use:** a load balancer/orchestrator needs liveness/readiness signals;
automated alerting on degradation; verifying downstream dependencies are reachable;
enabling self-healing by removing unhealthy instances from rotation.
**Pillars:** Reliability, Operational Excellence, Performance Efficiency. **Related:**
Circuit Breaker, Retry, Ambassador.

### 25. Index Table
**Create indexes over fields frequently referenced by queries.**
**Problem:** Many NoSQL stores query efficiently only on the primary/partition key;
queries on other fields force a full scan.
**When to use:** queries frequently filter/sort on non-key attributes; the store lacks
native secondary indexes; trading storage/write overhead for faster reads.
**Pillars:** Reliability, Performance Efficiency. **Related:** Materialized View,
Sharding, CQRS.

### 26. Leader Election
**Elect one instance among peers to coordinate shared work.**
**Problem:** Multiple identical instances coordinating shared work (scheduling,
rebalancing) without coordination duplicate effort or corrupt shared state.
**When to use:** a peer group needs exactly one coordinator; the leader must be
re-electable automatically on failure; avoiding a statically-assigned coordinator as a
single point of failure.
**Pillars:** Reliability. **Related:** Scheduler Agent Supervisor, Competing Consumers.

### 27. Materialized View
**Pre-populate views over data that isn't ideally shaped for the required queries.**
**Problem:** A write-optimized normalized schema is often slow or impossible to query
with joins across tables/services, especially in NoSQL.
**When to use:** read queries need joins across stores/tables; the read pattern is
stable; a short write-to-view delay is tolerable; offloading complex query logic from the
application tier.
**Pillars:** Performance Efficiency. **Related:** CQRS, Event Sourcing, Index Table,
Cache-Aside.

### 28. Messaging Bridge
**An intermediary that lets incompatible messaging systems communicate.**
**Problem:** Organizations running multiple brokers (different protocol/format/infra)
can't exchange messages natively, creating data silos.
**When to use:** integrating systems on different messaging protocols/brokers; a gradual
migration between messaging platforms; cloud-to-on-prem messaging interoperability.
**Pillars:** Cost Optimization, Operational Excellence. **Related:** Anti-Corruption
Layer, Publisher/Subscriber, Strangler Fig.

### 29. Pipes and Filters
**Decompose complex processing into reusable, independent stages.**
**Problem:** Monolithic pipelines are hard to test, scale, or reuse; one stage's failure
takes down the whole pipeline; stages may need different scaling.
**When to use:** processing breaks into discrete independent steps; different steps need
different scaling/deployment; stages should be reorderable/testable independently.
**Pillars:** Reliability. **Related:** Competing Consumers, Queue-Based Load Leveling,
Choreography.

### 30. Priority Queue
**Prioritize messages so higher-priority work is processed first.**
**Problem:** A standard FIFO queue treats all messages equally; critical messages wait
behind low-priority ones.
**When to use:** multiple clients/tenants with different SLAs; certain message types
need tighter time bounds; preventing starvation of premium/critical workloads.
**Pillars:** Reliability, Performance Efficiency. **Related:** Competing Consumers,
Queue-Based Load Leveling, Throttling.

### 31. Publisher/Subscriber
**Announce events to multiple interested consumers asynchronously, without coupling
senders to receivers.**
**Problem:** A producer that notifies each consumer directly becomes tightly coupled to
every one of them; adding a consumer means changing the producer.
**When to use:** multiple consumers reacting independently to the same event; producers
and consumers evolving independently; adding consumers without touching the producer;
consumers processing at their own pace.
**Pillars:** Reliability, Security, Cost Optimization, Operational Excellence,
Performance Efficiency. **Related:** Choreography, Competing Consumers, Event Sourcing,
Queue-Based Load Leveling.

### 32. Quarantine
**Validate external assets against a quality bar before authorizing their use.**
**Problem:** External artifacts (images, packages, data, IaC modules) may carry
vulnerabilities or misconfiguration; consuming them unchecked exposes a supply-chain
risk.
**When to use:** consuming third-party container images/packages/libraries; compliance
requires pre-deployment scanning; gating promotion through quality tiers; needing
traceability for deployed artifact versions.
**Pillars:** Security, Operational Excellence. **Related:** Gatekeeper, Gateway
Offloading, Pipes and Filters.

### 33. Queue-Based Load Leveling
**A queue buffers between a task and the service it invokes, smoothing bursty load.**
**Problem:** Demand spikes can overwhelm a service; over-provisioning for peak wastes
resources the rest of the time.
**When to use:** bursty workload against a backend that scales slowly or is costly to
over-provision; decoupling submission rate from processing rate; flattening spikes
without losing requests.
**Pillars:** Reliability, Cost Optimization, Performance Efficiency. **Related:**
Competing Consumers, Priority Queue, Throttling, Bulkhead.

### 34. Rate Limiting
**Control how many requests a client/service can send or receive.**
**Problem:** Without limits, a misbehaving or compromised client exhausts shared
resources for everyone, or triggers provider-side throttling/cost spikes.
**When to use:** protecting shared resources from overconsumption; enforcing fair use
across tenants; staying under known backend capacity limits.
**Pillars:** Reliability. **Related:** Throttling, Bulkhead, Circuit Breaker,
Queue-Based Load Leveling.

### 35. Retry
**Transparently retry a failed operation that is likely a transient fault.**
**Problem:** Cloud environments see brief transient faults — network blips, service
restarts, momentary throttling — that aren't actually permanent failures.
**When to use:** the failure looks transient (429/503/timeout); the operation is
idempotent or safe to repeat; improving resilience without a full failover.
**Pillars:** Reliability. **Related:** Circuit Breaker, Bulkhead, Ambassador, Health
Endpoint Monitoring.

### 36. Saga
**Manage data consistency across microservices in a distributed-transaction scenario.**
**Problem:** Two-phase commit across independently-owned databases isn't feasible;
without coordination, partial failures leave the system inconsistent.
**When to use:** a business operation spans multiple services, each with its own store;
eventual consistency with well-defined compensation is acceptable; each step is
reversible by a compensating action.
**Pillars:** Reliability. **Related:** Compensating Transaction, Choreography, Scheduler
Agent Supervisor, Event Sourcing.

### 37. Scheduler Agent Supervisor
**Coordinate a set of distributed actions as a single logical operation, retrying or
compensating on failure.**
**Problem:** Multi-step distributed workflows need a way to track progress, detect
failure, retry/compensate, and reach a terminal state.
**When to use:** a workflow spanning multiple remote services needing orchestration;
centralized monitoring of workflow progress; automatic retry/compensation; guaranteed
completion or rollback.
**Pillars:** Reliability, Performance Efficiency. **Related:** Saga, Compensating
Transaction, Leader Election, Retry.

### 38. Sequential Convoy
**Process related messages in order, without blocking other groups.**
**Problem:** Ordering is required within a logical group but a global strict order would
serialize the whole system and destroy throughput.
**When to use:** messages within a group must stay ordered (order events, session
events); different groups can run concurrently; out-of-order processing within a group
would corrupt data.
**Pillars:** Reliability. **Related:** Competing Consumers, Priority Queue,
Queue-Based Load Leveling.

### 39. Sharding
**Divide a data store into horizontal partitions/shards.**
**Problem:** A single server has finite storage/compute/I/O; vertical scaling becomes
prohibitively expensive and the server is a single point of failure.
**When to use:** a single store can't meet storage/throughput needs; geographic data
distribution for latency/compliance; horizontal scale-out; different data subsets with
different SLAs.
**Pillars:** Reliability, Cost Optimization. **Related:** Index Table, Materialized
View, Geode, Deployment Stamps.

### 40. Sidecar
**Deploy a component into a separate process/container alongside the main app for
isolation and encapsulation.**
**Problem:** Cross-cutting functionality (logging, monitoring, config, networking)
embedded directly in the app creates tight coupling and language lock-in.
**When to use:** cross-cutting functionality running alongside but isolated from the main
app; different language than the main app; extending functionality without modifying it;
a different lifecycle/scaling need than the main app.
**Pillars:** Security, Operational Excellence. **Related:** Ambassador, Gateway
Offloading, Compute Resource Consolidation.

### 41. Static Content Hosting
**Serve static content directly from object storage/CDN rather than the app server.**
**Problem:** Serving static files from the app server wastes compute meant for dynamic
content and limits scalability.
**When to use:** files that don't change per request; reducing load on web servers; CDN
acceleration for geographically distributed users; cost-effective, highly available
static hosting.
**Pillars:** Cost Optimization. **Related:** Valet Key, Geode, Cache-Aside.

### 42. Strangler Fig
**Incrementally migrate a legacy system by gradually replacing pieces with new
services.**
**Problem:** A big-bang rewrite of a large legacy system is risky and often fails; the
legacy system must keep operating during migration.
**When to use:** incrementally replacing a monolith; old and new systems must coexist;
reducing migration risk by delivering value incrementally; the legacy system is too
large/complex for a single-phase replacement.
**Pillars:** Reliability, Cost Optimization, Operational Excellence. **Related:**
Anti-Corruption Layer, Gateway Routing, Sidecar.

### 43. Throttling
**Control resource consumption by an instance, tenant, or the whole service.**
**Problem:** A demand spike or misbehaving tenant can exhaust shared resources,
degrading service for everyone; over-provisioning for worst case is wasteful.
**When to use:** enforcing SLAs/quotas per tenant; known capacity limits that must not be
exceeded; graceful degradation under load instead of total failure; preventing one
workload from monopolizing shared resources.
**Pillars:** Reliability, Security, Cost Optimization, Performance Efficiency.
**Related:** Rate Limiting, Bulkhead, Queue-Based Load Leveling, Priority Queue.

### 44. Valet Key
**Grant clients a token/key for restricted, direct access to a specific resource.**
**Problem:** Routing all data transfer through the application server creates a
bottleneck and cost; unrestricted direct client access to a data store is a security
risk.
**When to use:** minimizing app-server load for data-intensive transfers
(upload/download); granting time-limited, scope-limited access; offloading transfer
bandwidth to a storage service; temporary access without full credentials.
**Pillars:** Security, Cost Optimization, Performance Efficiency. **Related:**
Gatekeeper, Static Content Hosting, Federated Identity.

---

> Generalized from the Azure Architecture Center's Cloud Design Patterns catalog. The
> patterns themselves are architectural concepts with no provider dependency; for the
> concrete service that implements the storage/queue/gateway/etc. a pattern calls for on
> a specific provider, see that provider's reference file.
