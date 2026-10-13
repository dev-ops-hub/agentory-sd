---
name: secure-engineering
description: Use when writing code that handles user input, credentials, secrets, or dependencies, before shipping it — baseline secure-coding checklist, independent of role or language
---

# Secure Engineering

## Overview

Baseline secure-coding principles that apply regardless of role, language, or framework: handling input, credentials, secrets, and dependencies safely by default. This is the floor every engineer builds on — not infrastructure security operations (network hardening, cloud IAM, incident response), which belongs to a platform/DevOps role.

For OWASP-depth application security (JWT pitfalls, auth implementation, API-specific attack classes), see the `application-security` skill in the Software Engineer agent's own library; this skill is the baseline every role shares.

## When to Use

- Writing any function that touches user input, a database, a shell command, or an external API
- Implementing authentication/credential handling, even for an "internal MVP" or "we'll harden it later" request
- Adding a new third-party dependency
- Writing anything that logs — logs are a common and underrated secret-leak vector

**Use this especially under deadline pressure.** A credential-handling decision made for speed (plaintext password comparison, logging a token "just for debugging," string-building a query) tends to get baked into stored data, log retention, or a public contract — "fix it next sprint" usually means "fix it after it's already in production data and someone depends on the broken behavior."

## Baseline Checklist

- [ ] **Never trust input.** Validate type, length, and range for every value crossing a boundary (user input, API payload, LLM output, another service's response) — before it's used, not after.
- [ ] **Parameterize, never interpolate.** SQL, shell commands, and any other command/query language: use parameterized queries or argument arrays, never string formatting with untrusted values. This applies even to "quick internal tool" code.
- [ ] **Hash credentials, always.** Passwords are hashed (bcrypt/argon2/scrypt — never a reversible scheme, never plaintext comparison), even for an internal-only or MVP build. There's no version of "we'll fix it later" that doesn't mean shipping real credentials into a database as plaintext first.
- [ ] **Secrets never appear in logs, error messages, URLs, or committed files.** Audit logs may record *who did what* (user ID, action, query parameters that aren't secrets) but never the secret itself (password, token, full card number, API key).
- [ ] **Least privilege by default.** A function that can read/write more than its caller needs is a bigger blast radius than one that can't — scope database roles, API scopes, and file permissions tightly.
- [ ] **Dependencies are vetted and pinned.** New dependency: check it's from a legitimate source, has a compatible license, and is pinned to a specific version — not a wildcard range.
- [ ] **Fail closed.** An error in an auth/permission check should deny access, not grant it. A caught exception should not silently become a success-shaped response.

## Why "Later" Doesn't Work for Credentials and Logging

Two categories are exceptions to normal "ship fast, harden later" tradeoffs, because the cost of doing it right is approximately the same as doing it wrong, and the deferred cost compounds:

1. **Credential storage.** Hashing on write costs the same effort as not hashing. Shipping plaintext means every row written from that point is a liability, and migrating later requires either a backfill (can't un-hash what you never had) or forcing a password reset for every user.
2. **Logging secrets.** Logging a secret "to debug this one issue" means it's now in log aggregation, retention, and anyone with log access — for as long as that log line is retained. There's no safe way to "clean it up later" once it's shipped to a log sink.

Rate limiting, pagination, full authz frameworks, and most other hardening genuinely can wait — scope those honestly as follow-up work rather than cutting the two items above.

## Common Mistakes

| Mistake | Fix |
|---|---|
| "It's just an internal tool" used to justify plaintext passwords | Hash regardless of audience — internal tools get breached too, and "internal" rarely stays true |
| Logging full request/response for debugging | Log identifiers and outcomes; strip or redact secret fields before the log call |
| String-formatting a query because it's "just a quick script" | Use parameterized queries even in throwaway code — the throwaway code is what ends up in production |
| Trusting LLM or upstream-service output because it's not "user input" | Validate it exactly as you would raw user input — it's still untrusted |
| Broad `except Exception: return success-shaped value` | Catch specific exceptions; let unexpected ones propagate or return a clearly-failed result |

## Quick Reference

| Touching... | Minimum bar |
|---|---|
| User/API/LLM input | Validate before use |
| SQL/shell/query construction | Parameterize, never interpolate |
| Passwords | Hash with bcrypt/argon2/scrypt, never plaintext |
| Logs | No secrets, tokens, or full credentials — ever |
| New dependency | Vetted source, pinned version |
| Auth/permission check failure | Deny by default |
