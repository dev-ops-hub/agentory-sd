# Sprintkit constitution rules

`planning/constitution.md` is the project constitution (written by `sprintkit-start`). Like spec-kit's `.specify/memory/constitution.md`, it is non-negotiable: every sprintkit skill and agent reads it and is held to it. If it does not exist yet, these rules do not apply. It is drafted from [.claude/templates/constitution-template.md](../templates/constitution-template.md), which fixes its structure (Core Principles, two project-specific sections, Governance, version footer).

## Four layers

1. **Loaded automatically.** The project `CLAUDE.md` imports it with `@planning/constitution.md`, so every session (including autopilot worktrees cut from `main`) starts with it in context.
2. **Read explicitly.** Every agent definition and every skill that reads the PRD reads the constitution too, and every brief sent to a subagent names `planning/constitution.md` with the instruction to read it first.
3. **Proven by a gate.** Outputs show it was applied, not just opened:
   - Agents start their result with `Constitution: v<X.Y.Z> read` (the version from its footer) and cite principles by number where they apply. A result without that line, or citing an old version, is re-dispatched.
   - `sprintkit-review` treats a violated MUST rule as a Blocker, quoting the principle.
   - `product-auditor` treats a PRD requirement that contradicts a MUST rule as P0, owned by `USER` (change the PRD or amend the constitution).
4. **Enforced by a hook.** [.claude/hooks/constitution-gate.sh](../hooks/constitution-gate.sh) blocks any `Agent` dispatch whose brief does not mention `constitution.md` while the file exists. Lookup-only agents (`Explore`, `claude-code-guide`, `statusline-setup`) are exempt.

## Brief line

Paste this into every subagent brief, verbatim:

> Read `planning/constitution.md` before anything else. Its MUST rules override this brief; if the task conflicts with one, stop and report the conflict instead of working around it. Start your result with `Constitution: v<version> read`.

## Conflicts

A conflict between the constitution and a PRD, sprint plan, spec or user request is never resolved silently. Surface it to the user with the principle number and the conflicting text. The two ways out are changing the other document, or amending the constitution through `sprintkit-start` (`args: "track:<track> constitution"`), which bumps its version.
