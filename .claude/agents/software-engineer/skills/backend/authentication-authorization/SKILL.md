---
name: authentication-authorization
description: Use when implementing login, session/token handling, or permission checks — JWT/session pitfalls, refresh-token rotation, and RBAC implementation
---

# Authentication & Authorization

## Overview

Implementing credential verification (authentication) and permission checks (authorization) correctly — the specific pitfalls in JWT/session handling and role-based access control. For the baseline "hash passwords, never log secrets" rules, see `secure-engineering`; this skill covers the implementation details beyond that floor.

## When to Use

- Implementing login, session creation, or token issuance/verification
- Adding refresh-token support
- Implementing role- or permission-based access control (RBAC)
- Reviewing existing auth code for a specific class of vulnerability

## Authentication: Sessions vs. Tokens

| Approach | Characteristics |
|---|---|
| **Server-side session** | Session ID in a cookie, state stored server-side (DB/Redis). Easy to revoke immediately (delete the session record). Requires session storage infrastructure. |
| **JWT (stateless token)** | Self-contained, no server-side lookup needed to verify. Cannot be revoked before expiry without an extra mechanism (denylist) — this is JWT's central tradeoff. |

Pick sessions when immediate revocation matters (e.g., "log out everywhere" must take effect instantly). Pick JWTs when statelessness/horizontal scaling without shared session storage matters, and accept short expiry + refresh as the revocation story.

## JWT Pitfalls

- **Verify the algorithm, don't trust the token's `alg` header.** A classic attack: a token with `"alg": "none"` or an attacker-chosen algorithm bypasses signature verification if the verifier blindly uses whatever the token claims. Pin the expected algorithm in the verification call; never derive it from the token itself.
- **Use a strong, server-only secret/key for HMAC, or asymmetric keys (RS256/ES256) when the token must be verified by a party that shouldn't be able to issue tokens.**
- **Short expiry on access tokens** (minutes, not days) — the shorter the expiry, the smaller the window a stolen token is useful.
- **Validate every claim you rely on** — `exp` (expiry), `iss` (issuer), `aud` (audience) — don't just check the signature and assume the payload is safe to trust blindly.

## Refresh Token Rotation

A stolen refresh token is a bigger risk than a stolen access token (longer-lived). Mitigate with rotation and reuse detection:

1. Each refresh issues a *new* refresh token and invalidates the old one.
2. If an already-used (rotated-out) refresh token is presented again, treat it as a signal of theft — invalidate the entire token family (all tokens descended from that one), not just the reused token.

```python
def refresh(old_refresh_token: str) -> TokenPair:
    record = refresh_token_store.get(old_refresh_token)
    if record is None:
        raise AuthError("invalid refresh token")
    if record.used:
        # reuse of an already-rotated token: possible theft
        refresh_token_store.invalidate_family(record.family_id)
        raise AuthError("refresh token reuse detected — all sessions revoked")
    refresh_token_store.mark_used(old_refresh_token)
    new_pair = issue_token_pair(record.user_id, family_id=record.family_id)
    return new_pair
```

## Rate Limiting Login/Refresh

Protect against credential-stuffing and brute-force without a race condition in the counter itself:

```python
# Atomic increment + conditional expiry avoids the race where two
# concurrent requests both read "under limit" before either increments
key = f"login_attempts:{username}"
attempts = redis.incr(key)
if attempts == 1:
    redis.expire(key, 900)  # 15 minute window
if attempts > 5:
    raise RateLimitError("too many attempts, try again later")
```

A plain "read count, check, increment" (not atomic) lets concurrent requests both pass the check before either increments — use an atomic `INCR` + `EXPIRE`, not read-then-write.

## Authorization: RBAC Implementation

- **Check authorization on every request that touches protected data, server-side** — never trust a client-side role claim without server-side verification against the current, authoritative role record.
- **Deny by default.** An unmatched permission check should deny, not fall through to allow.
- **Scope checks to the specific resource**, not just the general role — "is an admin" is not the same check as "is an admin of *this* account/tenant" in a multi-tenant system; a role check without a resource-ownership check is a common authorization bypass (the "BOLA/IDOR" class: swap an ID in the URL/payload and access someone else's resource).

```python
def get_order(user: User, order_id: str) -> Order:
    order = order_repo.find_by_id(order_id)
    if order is None:
        raise NotFoundError()
    # Resource-level check, not just "is this user authenticated"
    if order.customer_id != user.id and not user.has_role("support_agent"):
        raise ForbiddenError()
    return order
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Trusting the JWT's own `alg` header during verification | Pin the expected algorithm in the verifier call |
| Long-lived access tokens with no refresh flow | Short access-token expiry + refresh rotation |
| Refresh token reuse not detected | Rotate on every refresh; invalidate the whole family on reuse |
| Role check without resource-ownership check (IDOR) | Check both "has the role" and "owns/is scoped to this specific resource" |
| Non-atomic login-attempt counter | Use atomic `INCR` + `EXPIRE`, not read-check-increment |
| Trusting a client-supplied role/permission claim | Re-verify server-side against the authoritative record on every request |

## Quick Reference

| Need | Default |
|---|---|
| Must revoke sessions instantly | Server-side sessions, not JWT |
| Stateless, horizontally scaled auth | JWT with short expiry + refresh rotation |
| Verifying a JWT | Pin algorithm; validate `exp`/`iss`/`aud` |
| Refresh token presented twice | Reuse detection → invalidate the token family |
| Permission check | Deny by default; check role AND resource ownership |
