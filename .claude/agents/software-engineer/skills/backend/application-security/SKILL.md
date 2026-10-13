---
name: application-security
description: Use when writing or reviewing code for OWASP-class vulnerabilities, designing a secure API, or choosing a cryptographic primitive — application-level security depth beyond the baseline
---

# Application Security

## Overview

Implementation-depth application security: the OWASP Top 10 at the code level, secure API design, and correct use of cryptographic APIs. This builds on `secure-engineering` (the baseline every engineer applies by default) with the deeper patterns needed when security is the primary concern of a change — not infrastructure security (network/cloud hardening) or offensive security testing, which are out of scope for this role.

## When to Use

- Writing or reviewing code specifically for security (an auth flow, a payment handler, an admin tool)
- Designing an API that will be exposed to untrusted or semi-trusted clients
- Choosing how to encrypt, hash, or sign something
- A threat-modeling pass is needed before building a sensitive feature

## OWASP Top 10, at the Code Level

| Risk | What it looks like in code | Mitigation |
|---|---|---|
| **Injection** | String-built SQL/shell/LDAP queries | Parameterized queries, argument arrays (see `secure-engineering`) |
| **Broken authentication** | Weak session handling, no rate limiting on login | See `authentication-authorization` |
| **Broken access control** | Missing resource-ownership check (IDOR/BOLA) | Check role AND resource scope on every request |
| **Cryptographic failures** | Rolling your own crypto, using MD5/SHA1 for passwords, hardcoded keys | Use vetted libraries (see Cryptographic APIs below) |
| **Insecure design** | Security bolted on after the fact, no threat model for a sensitive flow | Threat-model before building (see STRIDE below) |
| **Security misconfiguration** | Verbose error messages leaking stack traces/internals to clients, default credentials left in place | Generic client-facing errors; detailed errors only in server-side logs |
| **Vulnerable/outdated components** | Unpinned or stale dependencies with known CVEs | Pin versions; monitor for known-vulnerability advisories |
| **Identification/auth failures** | See broken authentication | — |
| **Software/data integrity failures** | Deserializing untrusted data without validation, unsigned auto-updates | Validate/sign before trusting; avoid unsafe deserialization (`pickle`, `eval`-based parsers) on untrusted input |
| **SSRF** | Fetching a URL supplied by the user without restricting the target | Allowlist target hosts/schemes; block requests to internal/metadata IP ranges |

## Secure API Design

- **Rate limit by identity and by endpoint**, not just globally — a shared global limit lets one abusive client exhaust the budget for everyone.
- **Validate the full request shape**, not just the fields you read — an API that silently ignores unexpected fields can hide a client's incorrect assumptions about what it's sending; prefer strict schema validation that rejects unknown fields for internal APIs, be more lenient for public APIs expecting client version skew.
- **Don't leak existence through timing or error differences.** "User not found" and "wrong password" should return the same response shape and take roughly the same time, or an attacker can enumerate valid usernames.
- **SSRF guard for any server-side fetch of a user-supplied URL:** resolve the hostname, reject if it resolves to a private/loopback/link-local/cloud-metadata address (`169.254.169.254` and equivalents), and re-check after any redirect — a URL can resolve safely at validation time and redirect to an internal address at fetch time.

```python
import ipaddress
import socket

BLOCKED_RANGES = [ipaddress.ip_network(r) for r in (
    "127.0.0.0/8", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16",
    "169.254.0.0/16",  # includes cloud metadata endpoints
)]

def is_safe_fetch_target(hostname: str) -> bool:
    try:
        ip = ipaddress.ip_address(socket.gethostbyname(hostname))
    except OSError:
        return False
    return not any(ip in r for r in BLOCKED_RANGES)
```

## Cryptographic API Usage

- **Never implement your own cipher, hash, or random-number generator.** Use the standard library or a vetted package (`cryptography` in Python, `crypto` built-ins elsewhere).
- **Password hashing:** bcrypt, argon2, or scrypt — never a general-purpose hash (SHA-256/MD5) alone, even with a salt; those are fast by design, which is exactly wrong for password storage.
- **Random values for tokens/keys:** use a cryptographically secure random source (`secrets` module in Python, not `random`). `random` is predictable given enough samples and must never generate a token, session ID, or key.
- **Symmetric encryption:** AES-GCM (authenticated encryption) over AES-CBC alone — GCM gives you integrity checking, CBC without a separate MAC doesn't.
- **Store encryption keys separately from the data they protect**, and rotate them on a defined schedule.

## STRIDE Threat Modeling (Lightweight)

For a sensitive feature, before building, run through STRIDE to find what to design against:

| Category | Ask |
|---|---|
| **S**poofing | Can someone impersonate a legitimate user/service? |
| **T**ampering | Can data be modified in transit or at rest without detection? |
| **R**epudiation | Can an action happen with no record of who did it? |
| **I**nformation disclosure | Can data be exposed to someone who shouldn't see it? |
| **D**enial of service | Can a single request/user exhaust a shared resource? |
| **E**levation of privilege | Can a low-privilege actor gain higher privilege? |

A few minutes of STRIDE on a sensitive flow (payments, admin tools, auth) before writing code catches entire classes of issues that are expensive to retrofit.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Using SHA-256/MD5 (even salted) for password storage | bcrypt/argon2/scrypt |
| Using `random` for a token or session ID | Use `secrets` (or the language's CSPRNG) |
| Fetching a user-supplied URL with no SSRF guard | Validate target isn't private/loopback/metadata range, re-check after redirects |
| Returning different errors/timing for "no such user" vs. "wrong password" | Same response shape and timing for both |
| Leaking stack traces or internal details in API error responses | Generic client-facing error; log details server-side only |
| Building a sensitive feature without a threat-modeling pass | Run STRIDE first, even briefly |

## Quick Reference

| Need | Default |
|---|---|
| Hash a password | bcrypt / argon2 / scrypt |
| Generate a token/session ID/key | CSPRNG (`secrets`), never `random` |
| Encrypt data at rest/in transit | AES-GCM (authenticated), vetted library only |
| Server-side fetch of a user-supplied URL | SSRF allowlist/IP-range guard, re-checked after redirects |
| Before building a sensitive feature | Quick STRIDE pass |
