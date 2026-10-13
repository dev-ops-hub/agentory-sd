---
name: engineering-documentation
description: Use when documenting a technical decision, writing a README or module-level doc, or deciding what deserves a comment versus what doesn't
---

# Engineering Documentation

## Overview

What to write down, and in what format, so technical decisions and non-obvious reasoning survive past the current conversation — without turning every change into a documentation chore.

## When to Use

- A technical decision was made that affects architecture, a dependency choice, or a pattern future work should follow → write an ADR (see below)
- A module, service, or script needs orientation for someone new to it
- Deciding whether a piece of code needs a comment at all

## Architecture Decision Records

For any decision affecting system architecture, technology selection, or a pattern future development should follow, use the shared `develop-adr` skill (`.claude/agents/shared-skills/develop-adr/`) — it has the full Nygard-format instructions, template, and worked example. Don't duplicate that content here; read it directly when an ADR is needed.

Signal that something is ADR-worthy: it would be a real cost to reverse, or a future engineer would reasonably ask "why did we do it this way?" without an obvious answer from the code alone.

## Code Comments

Default to none. A comment earns its place only when it carries information the code itself cannot: a non-obvious constraint, a workaround for a specific bug or upstream limitation, or behavior that would genuinely surprise a careful reader.

```python
# ❌ Restates what the code already says
# increment counter by 1
counter += 1

# ✅ Explains a non-obvious WHY
# Retried once because the upstream API returns a transient 502 under
# load roughly 1% of the time; see incident-2024-03-12.
response = retry_once(call_upstream)
```

If removing a comment wouldn't confuse a future reader, it shouldn't be there. Never write a comment that references the current ticket, PR, or "the X fix" — that context belongs in the commit message or PR description, not in code that outlives both.

## READMEs and Module-Level Docs

A README (or module docstring) answers, in this order:
1. What does this do, in one or two sentences?
2. How do I run/use it? (the minimum commands, not a full tutorial)
3. What should I know before changing it? (non-obvious constraints, where the tests live, what NOT to touch casually)

Keep it current with the code, or delete it — a stale README actively misleads, which is worse than no README.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Commenting what the code already says | Delete the comment; if it's not obvious, rename instead |
| Writing an ADR for a reversible, low-stakes choice | Save ADRs for decisions with real reversal cost |
| Referencing "the current fix" or ticket number in a comment | Put that in the commit message/PR description instead |
| Letting a README drift from the actual code | Update it in the same change, or remove it |

## Quick Reference

| Need | Use |
|---|---|
| Record an architecture/technology decision | `develop-adr` shared skill |
| Explain non-obvious code behavior | A short comment, only if removing it would confuse someone |
| Orient a new reader to a module | A short README: what, how to run, what not to touch |
