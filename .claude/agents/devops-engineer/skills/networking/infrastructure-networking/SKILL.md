---
name: infrastructure-networking
description: Use when designing or troubleshooting network topology — VPC/VNet subnetting, DNS, load balancing, private connectivity, firewalls, or TLS termination
---

# Infrastructure Networking

## Overview

Operational cloud/platform networking: how traffic is segmented, routed, balanced and secured at the network layer. Cloud-provider-specific VPC/VNet mechanics live in `skills/cloud/<provider>`; this skill is the provider-neutral layer underneath.

## When to Use

- Designing subnet tiers and CIDR allocation for a new environment
- Setting up DNS, a load balancer, or private connectivity between networks
- Reviewing firewall/security-group rules
- Diagnosing a network-layer connectivity failure (see also `skills/troubleshooting/infrastructure-troubleshooting`)

## Subnetting

Tier by trust/exposure, not by application: public (internet-facing load balancers/NAT), private-app (application workloads, no direct internet route), private-data (databases, no route to the internet at all, often not even outbound). Size CIDR blocks for real headroom — a /24 subnet (251 usable addresses) that's already at 200 allocated addresses from autoscaling will fail silently when it runs out, usually under the exact traffic spike that triggered the scale-out. Reserve non-overlapping CIDR ranges across environments/regions from the start if VPN/peering/transit-gateway connectivity between them is ever plausible — overlapping CIDRs discovered after the fact require a disruptive re-IP.

## DNS

Private DNS zones for internal service discovery (so internal hostnames don't leak to public DNS and don't depend on public resolution working). Split-horizon DNS (same hostname resolves differently inside vs. outside the network) is powerful but easy to debug wrong — when troubleshooting a resolution issue, always confirm which resolver context the request actually went through before assuming a DNS record is misconfigured.

## Load Balancing

| Layer | Use for |
|---|---|
| L4 (TCP/UDP) | Non-HTTP protocols, or when the LB itself shouldn't terminate TLS |
| L7 (HTTP/HTTPS) | Path/host-based routing, TLS termination, WAF integration |

Health checks on the load balancer must match what readiness actually means for the backend (the same readiness-vs-liveness distinction as `skills/containers/kubernetes`) — a load balancer health check hitting `/` on an app whose real dependency check lives at `/health` will keep routing traffic to an instance that can't actually serve requests.

## Private Connectivity

VPN (site-to-site or client) for lower-throughput, easier-to-provision connectivity; dedicated interconnect (Direct Connect/ExpressRoute/Cloud Interconnect) for consistent high-throughput, lower-latency links where VPN's internet-path variability isn't acceptable. VPC/VNet peering connects two networks within the same cloud directly; a transit gateway/hub model scales better than full-mesh peering once more than a handful of networks need to interconnect, since peering doesn't transit (A peered to B peered to C does not let A reach C).

## Firewalls / Security Groups

Default-deny inbound, explicit allow by source + port + protocol — the same default-deny posture as Kubernetes NetworkPolicy, applied one layer down. Reference other security groups/tags as the source where the platform supports it, rather than hardcoding IP ranges that drift from reality as infrastructure changes.

## TLS

Terminate TLS at the load balancer/ingress layer for most cases (lets a WAF/LB inspect traffic, centralizes certificate management); re-encrypt (TLS all the way to the backend) when compliance or a zero-trust posture requires encryption-in-transit even inside the private network, not just at the edge. Automate certificate issuance and renewal (cert-manager, cloud-native certificate managers) — a manually-tracked certificate expiry is a recurring, entirely preventable outage class.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Undersized subnet CIDR for autoscaling headroom | Size for peak scale-out, not current steady state |
| Overlapping CIDRs across environments discovered after VPN/peering is needed | Allocate non-overlapping ranges from the start |
| Load balancer health check that doesn't match real backend readiness | Point it at the actual readiness endpoint |
| Expecting transitive VPC peering (A-B-C) | Use a transit gateway/hub for more than a couple of interconnected networks |
| Manually tracked certificate expiry | Automate issuance and renewal |
