# Source

The `ux-designer` agent's skill library mixes files vendored from a third-party repository and files written for this repository. The agent reads them on demand; they are not auto-loaded as skills (they live outside `.claude/skills/`).

Upstream: [plugin87/ux-ui-agent-skills](https://github.com/plugin87/ux-ui-agent-skills), commit `f2e2f7f` (2026-09-16), MIT, copyright (c) 2026 Thientan Soparat.

| Path here | Origin (upstream path) | Version | License | Local changes |
|---|---|---|---|---|
| `skills/design-doctrine`, `design-component`, `data-dashboard`, `design-tokens`, `apply-aesthetic`, `design-review`, `a11y-audit`, `ux-writing`, `prototype` | `.claude/skills/<name>/SKILL.md` | commit `f2e2f7f` | MIT | None |
| `rules/` (accessibility, components, tokens-and-color, typography-and-spacing, review-and-research, brand-and-operations) | `.claude/rules/<name>.md` | commit `f2e2f7f` | MIT | None |
| `reference/components/` | `components/*.md` | commit `f2e2f7f` | MIT | None |
| `reference/accessibility/` (wcag-checklist, aria-patterns, cognitive, vision) | `accessibility/*.md` | commit `f2e2f7f` | MIT | None |
| `reference/content/voice-tone.md` | `content/voice-tone.md` | commit `f2e2f7f` | MIT | None |
| `reference/taste/design-taste.md` | `taste/design-taste.md` | commit `f2e2f7f` | MIT | None |
| `reference/tokens/` (colors, data-viz, typography, spacing, states) | `tokens/*.json` | commit `f2e2f7f` | MIT | None |
| `reference/workflows/` (prototyping, design-review) | `workflows/*.md` | commit `f2e2f7f` | MIT | None |
| `reference/examples/trading-terminal.html` | `examples/terminal/index.html` | commit `f2e2f7f` | MIT | Renamed only |
| `skills/designing-user-interfaces` | Written for this repository | n/a | Same terms as this repository | n/a |

## Upstream URLs

Pinned to the commit above: <https://github.com/plugin87/ux-ui-agent-skills/tree/f2e2f7fcc5cb9d99bbd8ec5e0d75cebb98e21e7e>. Each upstream path in the table is relative to that URL.

## Notes

- The upstream skills were written for a repo with a shell and a browser. They name scripts (`node scripts/...`, `python3 scripts/...`), slash commands (`/gate`, `/critique`, `/grill-me`) and a render step. The `ux-designer` agent has no shell, so [`../ux-designer.md`](../ux-designer.md) tells it to ignore those and to list each unrun check under "Verification still to run"; the vendored files are unedited.
- Not vendored: the 138 design systems under `design-systems/`, the code skills (`design-code`, `image-to-code`, `token-build`, `migrate-design-system`, `figma-integration`), `governance`, `performance`, `design-qa` and `redesign` (they need a shell or are out of scope for design specs), the upstream `design-critic` agent, and the `scripts/` gates. The agent can read a named design system from the upstream URL with WebFetch when the owner picks one.
- The upstream skills assume a repo-root layout (`components/atoms.md`, `.claude/rules/...`). The path map in the agent definition tells the agent where those files live here.
- The upstream skills are component-library-agnostic. This project ships daisyUI 5 as a skill (`.claude/skills/daisyui/`), so [`../ux-designer.md`](../ux-designer.md) has a "Component library: daisyUI" section telling the agent to read it with Read (it has no `Skill` tool) and to express the design system in daisyUI's component and token vocabulary when it is installed. That section resolves the skill across four scopes in precedence order — project (`.claude/skills/daisyui/`), user (`~/.claude/skills/`), plugin (`~/.claude/plugins/cache/**/skills/`) and enterprise — and falls back to the generic `design-component`/`design-tokens` vocabulary plus a `[USER]` Gap when no scope has it. The agent has no shell and cannot install it; the Gap recommends the project scope, since that is the only one committed and version-pinned. No vendored file was edited for this; the two touched files (`skills/designing-user-interfaces/SKILL.md` and its `references/TEMPLATE-tokens.md`) were written for this repository.
- `designing-user-interfaces` was tested per superpowers:writing-skills on one screen (the main trading screen). Baseline (persona only, no skill): a sound layout, but no decision log with options and IDs, no tokens or state matrix, and a contrast target stated as fact. With the skill: nine decisions with options, trace and rationale, a screen Rationale citing them, a state matrix, tokens, and every contrast pair tagged `UNVERIFIED`. One screen and one run each; not a full pressure test.

## Refreshing

Copy the same paths from a newer upstream commit, update the commit and date above, and record any edit to a vendored file in **Local changes**.
