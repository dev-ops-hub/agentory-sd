# Formats

## planning/scratchpad/jira-export.md

One section per level, in creation order. Each item is a heading with its fields; omit levels outside `levels`.

```markdown
# Jira export: <track>
Generated <YYYY-MM-DD> from the PRD, Sprint file and specs. Site <site>, project <project-prefix>, board <board-id>. Jira configured: yes | no.

## Epics
### EP-1 | <title> | Priority High | Labels: sprintkit, EP-1, FR-3, FR-4
Description: <summary, objective, benefits>
Jira: <key or "not created">

## Stories
### US-101 | <title> | Epic EP-1 | Sprint 2 | Priority High | Labels: sprintkit, US-101, FR-3
Description: <As a... I want... so that...>
Acceptance criteria: <Given/When/Then, one per line>
Edge cases: <rows>
Jira: <key or "not created">

## Sprints
### Sprint 2 | <name> | Stories: US-101, US-102 | Blocked by: Sprint 1
Jira sprint id: <id or "not created">

## Sub-tasks
### US-101/AC-1 | <title> | Parent US-101
Spec: planning/specs/sprint-2.md
Jira: <key or "not created">
```

## planning/scratchpad/jira-mapping.json

Plan IDs to Jira identifiers and document paths (relative to `planning/`, no extension) to Confluence pages. No credentials, no content copy.

```json
{
  "site": "your-company.atlassian.net",
  "project-prefix": "TDA",
  "exportedAt": "2026-10-04",
  "epics": { "EP-1": "TDA-10" },
  "stories": { "US-101": "TDA-12" },
  "sprints": { "2": 502 },
  "subtasks": { "US-101/AC-1": "TDA-14" },
  "comments": { "US-101-3": "10045" },
  "speclinks": { "TDA-12": { "url": "https://your-company.atlassian.net/wiki/spaces/TDA/pages/123/Sprint+2+spec", "linkId": 10000 } },
  "confluence": { "specs/sprint-2": { "pageId": "123", "url": "https://your-company.atlassian.net/wiki/spaces/TDA/pages/123/Sprint+2+spec", "sourceHash": "<sha256 of the markdown>" } }
}
```

Sprint values are Jira sprint ids (numbers); every other value is an issue key or a comment id.

## planning/scratchpad/jira-comments.md

Append-only decision log. One block per decision, using the seven-section template below. Every section is required; write `None` where nothing applies, never leave one out, so a reader who missed the conversation can still follow the decision.

```markdown
## US-101-3 | US-101 | product-manager | 2026-10-04
Title: <short name of the decision>
Decided by: agent | user-confirmed, <how it is covered>
Supersedes: <earlier decision id, if any>
Posted: <comment id, or "not posted">

Context
<What situation or question prompted the decision, in plain language a reader who missed the conversation can follow.>

Decision
<What was decided, and what it applies to.>

Example
<A concrete scenario with real values showing how the decision changes behaviour.>

Why
<Why it was decided this way.>

Rejected
<Other options considered and why each was rejected.>

Impact
<Effect on user stories, functional requirements, tests and other artefacts, by ID (US-n, FR-n, TC-n, NFR-n, EP-n).>

Dependencies
<How it works with other stories, epics or decisions, by ID.>
```

The Jira comment is built from the same block. Use exactly this layout, in markdown, with the two labels and the seven section headings in bold:

```markdown
[sprintkit:decision:<id>] <Title>

**Author who posted this comment**: <agent name, or the user> · <date>

**Decided by**: <agent | user-confirmed>, <how it is covered>

**Context**
<What situation or question prompted this decision.>

**Decision**
<What was decided, and what it applies to.>

**Example**
<A concrete scenario with real values.>

**Why**
<Why it was decided this way.>

**Rejected**
<Other options considered, and why each was rejected.>

**Impact**
<Effect on user stories, requirements and tests, by ID.>

**Dependencies**
<How it works with other stories, epics or decisions, by ID.>
```

The first line is the marker plus the title and stays plain so the marker can be found. `how it is covered` is one of: `confirmed by the user on <date>`, `covered by PRD approval`, `assumption, not yet confirmed`, or `confirmed in part: <which part>`. An agent decision the user has not confirmed always says so on the **Decided by** line. Keep it plain language, no jargon the user has not met, and define any abbreviation (Q-24, R-15) the first time it appears or replace it with its meaning.

## Decisions block (what agents return)

Each of `product-manager`, `technical-product-manager` and `product-auditor` ends its result with a **Decisions** block, at most five entries per story, one per decision about a story or epic (split, priority, deferral, assumption, conflict resolution, finding that changed a story). Entry fields: story or epic ID, title, decided by (`agent` or `user-confirmed`), then the seven sections of the template above in order: Context, Decision, Example, Why, Rejected, Impact, Dependencies. Every section is filled in; an entry with a section missing is incomplete and the orchestrator sends it back. The orchestrator numbers the entries and appends them to `planning/scratchpad/jira-comments.md`; agents never write files or call Jira.
