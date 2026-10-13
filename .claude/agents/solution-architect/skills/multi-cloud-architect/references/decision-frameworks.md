# Decision Frameworks

Provider-neutral method for choosing technology, comparing providers, and validating an
existing architecture. Fill in the specifics from whichever provider reference(s) apply.

---

## Technology Choice Approach

For each technology area (compute, storage, database, messaging, networking, API
management, containers, AI/ML):

1. **Start with requirements** — workload type, scale needs, latency/throughput targets,
   team expertise, compliance/data-residency constraints.
2. **Narrow to 2–3 candidates** within the chosen provider using that provider's
   reference file and its decision tables.
3. **Follow that provider's decision-tree guidance** (each provider reference links or
   describes its own).
4. **Validate against constraints** — budget, compliance, regional service availability,
   existing infrastructure, team familiarity.

Never skip step 1. A service choice justified only by "it's the newest/most popular
option" is not a decision, it's a guess.

---

## Architecture Review Workflow (new design)

1. **Identify requirements**:
   ```
   Functional: what must the system do?
   Non-functional:
     - Availability target (e.g., 99.9%, 99.99%)
     - Latency requirements (p50, p95, p99)
     - Throughput (requests/sec, messages/sec)
     - Data residency and compliance
     - Recovery targets (RTO, RPO)
     - Cost constraints
   ```
2. **Select an architecture style** — match requirements to a style in
   `architecture-principles.md` using its selection criteria.
3. **Choose the technology stack** — apply the Technology Choice Approach above, in the
   detected provider.
4. **Apply design patterns** — select from the 44 in `design-patterns.md` based on the
   concerns the requirements surfaced.
5. **Address cross-cutting concerns** — identity & access, monitoring, security, CI/CD —
   using `security.md` and the provider reference.
6. **Validate against the provider's own well-architected framework** (named per-provider
   — see that provider's reference) and the neutral tradeoff matrix in
   `architecture-principles.md`.
7. **Document decisions** as ADRs:
   ```markdown
   # ADR-NNN: [Decision Title]
   ## Status: [Proposed | Accepted | Deprecated]
   ## Context
   [What is the issue we're addressing?]
   ## Decision
   [What did we decide and why?]
   ## Consequences
   [What are the positive and negative impacts?]
   ```

---

## Multi-Cloud Comparison Methodology

Used when the user asks to compare providers, pick one for a new workload across
options, or evaluate portability/multi-cloud.

1. **Establish the architectural requirements first** — same list as step 1 above. Do
   not start from a service-name table; starting there anchors the comparison on
   superficial similarity instead of actual fit.
2. **Compare each named provider's actual capability against those requirements**,
   reading that provider's own reference file for the real behavior (limits, consistency
   model, regional availability, operational model) — not just the service name.
3. **Identify meaningful differences, not name mappings.** For each requirement, ask:
   - **Security** — what's the identity/access model, and does it meet the requirement
     natively or need extra work?
   - **Networking** — regional vs. global network scope, private connectivity options,
     latency characteristics.
   - **Operational complexity** — how much undifferentiated operational work does each
     option leave on the team?
   - **Scalability** — documented limits/quotas relevant to the workload's scale.
   - **Availability** — what HA/multi-region model does the specific service actually
     support (don't assume all "relational database" options behave the same across
     providers — see Do Not Assume in SKILL.md).
   - **Cost** — pricing model (consumption vs. reserved vs. per-request) and how it
     behaves at the workload's expected scale, not list price alone.
   - **Vendor-specific constraints** — anything that increases lock-in risk or limits
     future portability, if portability matters to the requirements.
4. **Use `service-mapping.md` only to find candidate services to compare**, never as
   proof of equivalence. Two services in the same mapping row can differ in consistency
   model, operational maturity, or regional availability.
5. **Give a recommendation with explicit rationale** tied back to the requirements from
   step 1 — not "Provider X is more popular" or "the names map more cleanly."

---

## Architecture Validation Checklist (reviewing an existing design)

Work through each item; grade findings by severity (blocks launch / likely rework /
polish) with a concrete fix and rationale.

| # | Check | Look for |
|---|---|---|
| 1 | **Assumptions** | What is implicitly assumed about scale, traffic pattern, data shape, or team process that isn't written down anywhere? |
| 2 | **Single points of failure** | Any component without redundancy that the whole system depends on — compute, data, network path, or a manual process. |
| 3 | **Network boundaries and traffic flows** | Is every flow between tiers/services labeled with protocol, direction, and the rule that allows it? Any traffic crossing a trust boundary without going through a control point? |
| 4 | **IAM and least privilege** | Any broad/basic-role grant where a narrower one would do? Any workload using a static credential where workload identity is available? |
| 5 | **Private connectivity vs. internet dependency** | Does anything that should be private-only have a public endpoint? Does critical functionality depend on reaching the public internet with no fallback? |
| 6 | **HA/DR** | Does the stated RTO/RPO match what the actual deployment topology can deliver? Has failover actually been tested, not just configured? |
| 7 | **Observability** | Can an on-call engineer diagnose a production incident from what's instrumented today? Are alerts tied to user-facing signals, not just raw infrastructure metrics? |
| 8 | **Scalability and quotas** | Does the design run into a documented provider quota/limit before it runs into a business-defined scale target? |
| 9 | **Operational complexity** | Does the team's actual operational maturity match what this design demands (e.g., self-managed Kubernetes vs. team size)? |
| 10 | **Cost** | Does the pricing model match the workload's actual traffic shape (e.g., per-request billing under sustained high load, or reserved capacity under spiky/idle load)? |

---

> The shapes in this file (requirements-first, decision-tree narrowing, ADR documentation,
> validation checklist) are provider-neutral by design. Service-specific decision tables
> live in each provider's reference file.
