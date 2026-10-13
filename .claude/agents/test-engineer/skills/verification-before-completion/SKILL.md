# verification-before-completion (shared skill)

This skill is used by more than one agent, so its content lives once in the shared folder:
[`.claude/agents/shared-skills/verification-before-completion/`](../../../shared-skills/verification-before-completion/)

Read this instead of this file:
- `.claude/agents/shared-skills/verification-before-completion/SKILL.md`

How test-engineer uses it: this is central to the role. Every PASS/FAIL/BLOCKED/AT-RISK conclusion, and every "all tests pass" or "bug fixed" claim, requires a fresh verification command run in the same message — see `../test-evidence/SKILL.md` for how this agent packages that evidence into a QA report.

Origin, version and license: `.claude/agents/shared-skills/SOURCE.md`.
