# Source

The `solution-architect` agent's skill library (`skills/`) mixes vendored third-party skills and files written for this repository. Each origin keeps its own license. The agent reads these files on demand; they are not auto-loaded as skills (they live outside `.claude/skills/`).

| Skill | Origin | Version | License | Local changes |
|---|---|---|---|---|
| multi-cloud-architect | Written for this repository. Supersedes the four rows below (removed 2026-10-07): the provider-neutral content (10 design principles, 6 architecture styles, 44 design patterns, antipatterns, HA/DR framework, security model, decision frameworks) is a generalized rewrite of `cloud-solution-architect`'s Azure-flavored originals; `references/azure.md` is a direct extraction of that same skill's Azure-specific content; `references/aws.md` and `references/gcp.md` are freshly written, using facts mined from `aws-serverless-eda`, `aws-cost-operations` and `gcp-cloud-architect` for accuracy (not copied verbatim) | — | Same terms as this repository | Derived from MIT-licensed (`cloud-solution-architect`, `aws-serverless-eda`, `aws-cost-operations`) and MIT + Commons Clause-licensed (`gcp-cloud-architect`) vendored skills; no verbatim text retained from the Commons-Clause source |
| develop-adr | Shared skill: the folder here holds only a `SKILL.md` pointer to `../shared-skills/develop-adr/`. Origin, version and license are in [`../shared-skills/SOURCE.md`](../shared-skills/SOURCE.md) | pm-skills 2.33.0 | Apache-2.0 | None |
| designing-system-architecture | Written for this repository | — | Same terms as this repository | — |

## Superseded Vendored Skills (removed 2026-10-07)

These four skills were vendored, read directly by `multi-cloud-architect`'s authoring pass for factual accuracy, and then removed once that skill existed. Kept here for provenance/license history, since `multi-cloud-architect` derives from them.

| Skill | Origin | Version | License |
|---|---|---|---|
| cloud-solution-architect | [microsoft/skills](https://github.com/microsoft/skills), `.github/skills/cloud-solution-architect` | commit `ce7edea` (2026-10-02) | MIT |
| gcp-cloud-architect | [borghei/Claude-Skills](https://github.com/borghei/Claude-Skills), `engineering/gcp-cloud-architect` | commit `5318eda` (2026-09-27), skill v1.1.0 | MIT + Commons Clause |
| aws-serverless-eda | [zxkane/aws-skills](https://github.com/zxkane/aws-skills), `plugins/serverless-eda/skills/aws-serverless-eda` | commit `68530c6` (2026-06-15) | MIT |
| aws-cost-operations | zxkane/aws-skills, `plugins/aws-cost-ops/skills/aws-cost-operations` | commit `68530c6` (2026-06-15) | MIT |

## Upstream URLs

Where each superseded third-party skill was obtained, as a public URL pinned to the version vendored here. Skills written for this repository (including `multi-cloud-architect`) have no upstream.

| Skill | Obtained from |
|---|---|
| cloud-solution-architect | <https://github.com/microsoft/skills/tree/ce7edea90860e0c69fa36db164584c87908e09f5/.github/skills/cloud-solution-architect> |
| gcp-cloud-architect | <https://github.com/borghei/Claude-Skills/tree/5318eda16c134c500c237425404975545c0eedd2/engineering/gcp-cloud-architect> |
| aws-serverless-eda | <https://github.com/zxkane/aws-skills/tree/68530c6f296ccd2f5e99c79782f3e0fbf962c51a/plugins/serverless-eda/skills/aws-serverless-eda> |
| aws-cost-operations | <https://github.com/zxkane/aws-skills/tree/68530c6f296ccd2f5e99c79782f3e0fbf962c51a/plugins/aws-cost-ops/skills/aws-cost-operations> |

Shared skills (`develop-adr`): URLs are in [`../shared-skills/SOURCE.md`](../shared-skills/SOURCE.md).

## Notes

- The four superseded skills were written for interactive sessions with MCP servers, CLI tools and scripts; while vendored, the agent definition ignored those and used only the reference files. They have since been removed (2026-10-07) in favor of `multi-cloud-architect`, written for this repository and reasoning natively across all three providers instead of leaning on an Azure-flavored skill for cloud-neutral content.
- The Commons Clause that applied to `gcp-cloud-architect` forbade selling the software; vendoring it for use in this repository was allowed, and no verbatim text from it was carried into `multi-cloud-architect`.
- `multi-cloud-architect` was pressure-tested per superpowers:writing-skills (RED/GREEN against 3 scenarios: ambiguous provider, Azure→AWS mechanical translation, multi-cloud comparison). Baseline (no skill): silently defaulted to a provider with no clarification, and jumped to comparing services before establishing requirements. With the skill: asked for provider clarification when it was material, and followed the requirements-first comparison workflow.
- `designing-system-architecture` was tested per superpowers:writing-skills. Baseline (persona only, no skill): the design omitted sources for cost figures, ADRs and a relayable Gaps list. With the skill: every figure carried a basis, decisions became ADRs and open questions became `Q<k>` items.

## Refreshing

`multi-cloud-architect` is written for this repository, not vendored — refresh its content directly by editing the reference files when provider services or frameworks change, and record the change in its own file history, not here.
