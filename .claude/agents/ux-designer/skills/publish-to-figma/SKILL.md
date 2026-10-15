---
name: publish-to-figma
description: Render the design in planning/ux/ into a Figma file (tokens, components, screens) when agent-config/figma.json has enabled true. Use at the end of every ux-designer Design or Revise run, after the markdown is written. Does nothing when Figma is not enabled.
invocation: model
---

# Skill: Publish to Figma

The markdown in `planning/ux/` is the source of truth. This skill renders it into Figma so the owner can see it. It never changes a design decision; if Figma and the markdown disagree, the markdown wins.

## 1. Configured or not

Read `agent-config/figma.json`, ignoring every key that starts with `_`.

- **Enabled** only when `enabled` is `true` and either `file-url` is non-empty, or `plan-key` and `file-name` are both non-empty.
- Anything else (file missing, `enabled: false`, incomplete): do **not** call any Figma tool, do not search for the Figma MCP. Report one line, `Figma: not enabled`, and stop. This is a normal outcome, not a gap.

## 2. Preflight

1. Your Figma tools are `mcp__figma-remote-mcp__*`. If they are not available in this dispatch, or `whoami` fails, stop and return a `[USER]` Gap: "Figma is enabled in agent-config/figma.json but the Figma MCP is not connected; connect it and re-run." Do not fall back silently.
2. If `file-url` is set, extract the file key from it and confirm access with `get_metadata`. If the file is unreachable, stop with the same Gap, naming the URL.
3. Load the Figma usage rules the MCP provides (its `figma-use` skill or resource) before the first `use_figma` call. They are mandatory.

## 3. Build

Work only from the markdown files. Never invent a colour, size or component that is not in them.

| Page | Source | Content |
|---|---|---|
| `Tokens` | `design-tokens.md` | Variable collections in three tiers (primitive, semantic, component), light and dark modes if the file defines them |
| `Components` | `ux-design.md` and `components` sections | One component set per spec'd component, with variants and the eight states |
| `Screens` | `screens/*.md` | One frame per screen at each breakpoint its file names, built from the Components page |

Only build the pages listed in `pages`. When `file-url` is empty, create the file with `create_new_file` using `file-name` and `plan-key`.

Rules:
- Update in place. Find existing pages, variables and frames by name and replace their content; do not create duplicates on a re-run.
- Use the Tokens variables for every fill, stroke, radius and text style. No hard-coded values in a screen frame.
- Regions the spec marks as custom (candlestick chart, heatmap, depth chart) may be placeholder frames labelled as such, matching the spec's wording. Say so in the README line.
- Zero emoji in any layer name or text.
- Do not claim contrast or accessibility results from Figma. Those stay `UNVERIFIED` in the README.

## 4. Export renders

If `export-renders` is `true`, export each screen frame with `get_screenshot` or `download_assets` into `planning/ux/assets/<screen-id>-<breakpoint>.png` (for example `s01-desktop-1440.png`), and make sure the screen file embeds it under a `Visual design` heading with alt text. If an export fails, keep the old image and list the failure in Gaps.

## 5. Record

You may write only under `planning/ux/`, so record the result there:

- `planning/ux/README.md`: a `**Figma:**` line with the file link, the publish date, the pages built, and which regions are placeholders. Replace the existing line; do not stack lines.
- Each screen file: a `**Figma:**` line under its title linking the file.

## 6. Report

Add to the final message: `Figma: published to <url> (pages: ...)`, or `Figma: not enabled`, or the failure and its Gap. Nothing else about Figma.
