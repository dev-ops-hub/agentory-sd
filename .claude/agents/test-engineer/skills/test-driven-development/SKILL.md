# test-driven-development (shared skill)

This skill is used by more than one agent, so its content lives once in the shared folder:
[`.claude/agents/shared-skills/test-driven-development/`](../../../shared-skills/test-driven-development/)

Read this instead of this file:
- `.claude/agents/shared-skills/test-driven-development/SKILL.md`

How test-engineer uses it narrowly: the RED phase only, when writing a new automated test that reproduces a reported defect — write it, watch it fail for the expected reason, then hand the fix (GREEN) to the owning implementation agent. Verifying their fix means watching your RED test turn GREEN; this agent does not write the production code itself.

Origin, version and license: `.claude/agents/shared-skills/SOURCE.md`.
