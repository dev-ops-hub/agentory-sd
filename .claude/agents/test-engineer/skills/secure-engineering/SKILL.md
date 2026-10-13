# secure-engineering (shared skill)

This skill is used by more than one agent, so its content lives once in the shared folder:
[`.claude/agents/shared-skills/secure-engineering/`](../../../shared-skills/secure-engineering/)

Read this instead of this file:
- `.claude/agents/shared-skills/secure-engineering/SKILL.md`

How test-engineer uses it: validating security-related *functional* acceptance criteria (unauthorized requests rejected, roles can't reach forbidden actions, secrets absent from responses/logs) when a story's acceptance criteria call for it. Deep OWASP/threat-modelling assessment stays `security-auditor`'s job — this agent's security testing is functional verification, not an audit.

Origin, version and license: `.claude/agents/shared-skills/SOURCE.md`.
