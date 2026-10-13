# Source

The `frontend-developer` agent's skill library is vendored from several upstream repositories. The agent reads them on demand with `Read`; they are not auto-loaded as skills (they live outside `.claude/skills/`, so Claude Code's own skill loader never discovers them — only `frontend-developer.md` points at them).

These were originally installed at the top level (`.claude/skills/<name>/`) and tracked in `skills-lock.json`. They have been moved under this agent's own folder because they are frontend-specific reference material for one agent, not general-purpose skills every session should load; `skills-lock.json` now tracks only `daisyui`, which `ux-designer` and `frontend-developer` both still resolve from `.claude/skills/daisyui/`.

| Path here | Origin (upstream repo) | Version | License | Local changes |
|---|---|---|---|---|
| `angular-developer/` | [angular/skills](https://github.com/angular/skills), `angular-developer/SKILL.md` | 1.0, Copyright 2026 Google LLC | MIT | None |
| `angular-new-app/` | [angular/skills](https://github.com/angular/skills), `angular-new-app/SKILL.md` | 1.0, Angular Team @ Google | MIT | None |
| `nextjs-best-practices/` | Community skill (no pinned upstream repo), added 2026-02-27 | n/a | Unstated (`risk: unknown`) | None |
| `vercel-composition-patterns/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/composition-patterns/SKILL.md` | 1.0.0, vercel | MIT | None |
| `vercel-optimize/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/vercel-optimize/SKILL.md` | 1.2.0 | Unstated | None |
| `vercel-react-best-practices/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/react-best-practices/SKILL.md` | 1.0.0, vercel | MIT | None |
| `vercel-react-native-skills/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/react-native-skills/SKILL.md` | 1.0.0, vercel | MIT | None |
| `vercel-react-view-transitions/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/react-view-transitions/SKILL.md` | 1.0.0, vercel | MIT | None |
| `web-design-guidelines/` | [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills), `skills/web-design-guidelines/SKILL.md` | 1.0.0, vercel | Unstated | None |

## Notes

- `daisyui` is **not** vendored here. It stays at the project level (`.claude/skills/daisyui/SKILL.md`, pinned in `skills-lock.json`) because `ux-designer` resolves it there first in its four-scope lookup, and `frontend-developer.md`'s own daisyUI section must resolve to the same file so the two agents never disagree about what's installed.
- `angular-developer` and `vercel-react-native-skills` are read-only reference for this project: the constitution fixes the stack as Next.js static export, so `frontend-developer.md` only reaches for these two when a dispatched task explicitly names Angular or React Native/Expo.
- `vercel-optimize` ships its own `scripts/`, `lib/` and `references/` tooling built for a repo with a shell, Vercel CLI access and project telemetry. `frontend-developer` has a shell (`Bash` is in its tool list), but no Vercel account or deployed project in this repo yet; treat its scripts as aspirational until a Vercel project exists, and prefer its `references/*.md` playbooks over running its `.mjs` scripts blind.
- None of these vendored files were edited for this repo. Any correction belongs upstream, not here, so a refresh (see below) can be a clean overwrite.

## Refreshing

Fetch the same path from a newer upstream commit, overwrite the matching folder here, and update the version/notes above. `nextjs-best-practices` has no pinned source commit to refresh against; replace it only if a better-sourced version is found.
