# Source

The `software-engineer` agent's skill library (`skills/`) is written for this repository. It is informed by research into three third-party skill/agent collections, but no verbatim text from any of them is reused — see the research findings below for why, and for what each one contributed.

| Skill | Origin | License | Notes |
|---|---|---|---|
| software-architecture | Written for this repository | Same terms as this repository | Topic coverage (Clean/Hexagonal architecture, SOLID) informed by reading `wshobson/agents`' `architecture-patterns` (MIT) and `agentic-awesome-skills`' `architecture` (MIT/CC BY 4.0) skills for scope; no text copied |
| distributed-systems-patterns | Written for this repository | Same terms as this repository | Topic coverage (CQRS, event sourcing, saga) informed by `wshobson/agents`' `microservices-patterns`/`cqrs-implementation`/`event-sourcing-architect` (MIT) for scope; explicitly does NOT reuse `luxor-devops-suite`'s `enterprise-architecture-patterns`, which covers the same topics but has no valid license (see below) |
| api-design | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `api-design-principles`/`graphql-architect` (MIT) for scope |
| backend-development | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `backend-architect` (MIT) for scope |
| authentication-authorization | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `api-security-best-practices` (MIT, upstream community skill) for the JWT/refresh-token pitfalls covered |
| application-security | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `api-security-best-practices` and `threat-modeling` (MIT) for scope |
| integration-patterns | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `stripe-integration` (MIT) and `wshobson/agents`' `payment-integration` (MIT) for the idempotency/webhook patterns covered |
| database-design | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `postgresql-table-design` (MIT) and `wshobson/agents`' `database-migration` (MIT) for scope |
| sql-and-query-optimization | Written for this repository | Same terms as this repository | Informed by `wshobson/agents`' `sql-optimization-patterns` (MIT) for scope |
| test-strategy-and-automation | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `python-testing-patterns`/`e2e-testing-patterns` (MIT) for scope |
| clean-code-and-refactoring | Written for this repository | Same terms as this repository | Informed by `agentic-awesome-skills`' `clean-code` (ClawForge, MIT) and `wshobson/agents`' `legacy-modernizer` (MIT) for scope |
| languages/python | Written for this repository | Same terms as this repository | — |
| languages/typescript | Written for this repository | Same terms as this repository | — |
| frameworks/fastapi | Written for this repository | Same terms as this repository | — |

Shared skills used by this agent (`systematic-debugging`, `test-driven-development`, `code-review`, `secure-engineering`, `testing-principles`, `engineering-documentation`, `git-workflow`, `problem-decomposition`): origin, version and license are in [`../shared-skills/SOURCE.md`](../shared-skills/SOURCE.md).

## Research basis

Before writing any skill, three reference repositories were researched for candidate content, licensing and quality (full catalog not reproduced here — see the skill-architecture discussion that preceded this build for the complete Phase 1–11 analysis):

| Repo | License found | Verdict |
|---|---|---|
| [wshobson/agents](https://github.com/wshobson/agents) | MIT (root `LICENSE`, verified) | Reusable with attribution; 91 plugins with heavy internal duplication (same persona body copy-pasted across plugins with only the `name:` field changed) — used for topic/scope reference only, no verbatim text taken |
| [manutej/luxor-claude-marketplace](https://github.com/manutej/luxor-claude-marketplace) (`plugins/luxor-devops-suite/skills`) | **No LICENSE file exists**, despite an MIT claim in a README badge and `plugin.json` metadata; metadata also references a nonexistent `github.com/luxor/*` org | **Not reused.** Treated as all-rights-reserved by default. Two of its skills (`enterprise-architecture-patterns`, `hasura-graphql-engine`) were identified as software-engineering content mislabeled as "DevOps" — their *topic scope* (DDD/CQRS/Saga, GraphQL API design) informed what this agent's own `distributed-systems-patterns` and `api-design` skills should cover, but no text was copied from either |
| [sickn33/agentic-awesome-skills](https://github.com/sickn33/agentic-awesome-skills) | MIT (code/tooling) + CC BY 4.0 (docs) at repo root; individual skills carry their own `license`/`license_source` frontmatter pointing to their true upstream (mostly MIT, some Apache-2.0) — a curated aggregation of ~2,658 skills from many third-party sources | Reusable with attribution per-skill; used for topic/scope reference on several skills (see table above). Also flagged: ~80 offensive-security `hunt-*` skills (role mismatch, excluded) and 18 skills with a literal unfilled template placeholder as their description (broken scaffolds, excluded) |

## Testing

Per the writing-skills TDD methodology, three baseline (RED) pressure-test scenarios were run with fresh subagents, with no skill present, before any Common Engineering Skill covering that discipline was written:

- **Code review under deadline + social pressure** ("20 minutes to ship," "Priya already looked at it," friendly tone), reviewing a diff with a real SQL-injection bug and a dropped status check. Baseline: the agent still caught both issues, declined to approve, and was explicit that social/time pressure didn't reduce scrutiny.
- **Secure coding under deadline pressure** ("ship today," "compare password text for now, fix it later," "include query params in the log line"). Baseline: the agent refused the plaintext password comparison and refused to log the raw password, while complying with everything else requested (parameterized queries, audit logging of non-secret fields).
- **Test strategy under a Friday deadline** ("mock everything, 5-6 unit tests, that's enough right?"). Baseline: the agent pushed back, recommending additional tests for two real bugs it found in the example code (partial-reservation leak, charge-succeeds-but-order-create-fails) rather than accepting the proposed shortcut.

All three baselines already complied with the standard this skill set would otherwise enforce — no rationalization or shortcut-taking was observed even under combined pressure. Per the Iron Law ("no skill without a failing test first"), `code-review`, `secure-engineering`, and `testing-principles` were therefore written as **technique/reference skills** (checklists, decision tables, concrete patterns) rather than discipline-enforcing skills with an "Iron Law" + rationalization-table structure — there was no observed failure to bulletproof against, and prohibition-heavy framing is reserved for a demonstrated discipline gap (see `superpowers:writing-skills`'s "Match the Form to the Failure" guidance).

The two genuinely discipline-enforcing skills in this library — `systematic-debugging` and `test-driven-development` — were not re-tested from scratch; they are vendored from `superpowers` (MIT, Jesse Vincent), which documents its own RED/GREEN/REFACTOR testing history against pressure scenarios in its own repository. See `../shared-skills/SOURCE.md` for that provenance.

The remaining reference/technique skills (`api-design`, `database-design`, language/framework modules, etc.) were authored directly and reviewed for accuracy and scope rather than pressure-tested with subagents, per the agreed reduced-rigor plan for this build pass (full subagent pressure-testing reserved for discipline-enforcing skills only).
