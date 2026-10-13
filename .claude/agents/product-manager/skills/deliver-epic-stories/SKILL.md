---
name: deliver-epic-stories
description: Use when a PRD feature or goal is too big for one sprint and needs an epic written, when grouping related user stories under a parent, or when a backlog has many loose stories with no larger goal tying them together.
metadata:
  phase: deliver
  version: "1.0.0"
  category: specification
---
# Epics

An epic is a large, high-level work item too big for one sprint, completed over several. It sits below a theme, goal or initiative and above user stories, which are its parts (chapters of a book). Epics are deliberately broad with minimal detail so the stories under them can change between sprints. An epic never enters a sprint; only its stories do. Epics are an optional organising tool, not part of Scrum itself. Source: [Scrum Alliance, What Is an Epic in Agile](https://resources.scrumalliance.org/Article/epic-agile).

## When to Use

- A PRD feature or goal spans several sprints.
- Related stories need a shared parent, objective and benefit.
- A backlog has loose stories with no larger goal.

## When NOT to Use

- The work fits one sprint: write a story with `deliver-user-stories`.
- You need Given/When/Then for a story: `deliver-acceptance-criteria`.
- The feature itself is unspecified: `deliver-prd` first. Epics trace to documented requirements.

## Instructions

1. Read the PRD or feature description. If it carries requirement IDs (e.g. FR-n) or a constitution exists, note them; the epic traces to them.
2. Pick one objective per epic. Two unrelated objectives are two epics.
3. Fill `references/TEMPLATE.md` in its section order. Keep every section brief; an epic is a summary, not a spec.
4. In **User Stories/Features**, list one line per story (ID plus story statement). Do not write acceptance criteria here; hand stories to `deliver-user-stories`. If no stories exist yet, omit the section.
5. Check size: the epic must clearly need more than one sprint. If it is smaller, it is a story.
6. Omit optional sections (Mockups/Designs, User Stories) when empty rather than writing placeholders. Never invent dates, stakeholders or links; write `TBD` and list the gap.

## Output Format

Use `references/TEMPLATE.md`: Epic Summary, Objective, Benefits, User Stories/Features, Mockups/Designs, Dependencies, Timeframe, Stakeholders, Notes/Additional Information. See `references/EXAMPLE.md` for a completed epic.

## Quality Checklist

- [ ] One objective, stated as a business or user outcome
- [ ] Benefits are outcomes, not features
- [ ] Too big for one sprint
- [ ] Story lines use "As a... I want... so that..."; no acceptance criteria inside the epic
- [ ] Dependencies name real epics, stories or prerequisites
- [ ] Unknown dates and stakeholders are `TBD`, not guessed
- [ ] Traces to PRD requirement IDs where they exist
