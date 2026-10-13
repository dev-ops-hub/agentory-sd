---
name: writing-sprint-specs
description: Use when writing or revising the specification for one sprint of a sprintkit plan, so an engineer subagent can implement it and QA can test it, from a PRD, a sprint plan and a constitution
---

# Writing Sprint Specs

## Overview

A sprint spec turns one sprint's stories into numbered, traceable requirements, interfaces, acceptance criteria, edge cases and test cases. **Core principle:** the spec records what the sources say and makes every gap visible; it never quietly fills a product gap with a decision of its own. Two spec writers given the same inputs must produce specs that agree, differing only in wording.

## Inputs

PRD file, sprint plan file and sprint number, `planning/constitution.md` (if it exists), the codebase, and summaries of the sprints this one depends on.

## The spec

Fill `references/TEMPLATE.md` exactly: every section, in order, with the ID scheme below. A section that does not apply says so in one line; it is never deleted.

| ID | Meaning | Rule |
|---|---|---|
| `FR-<N>.<k>` | Functional requirement | One MUST statement, testable, with a **Source** (PRD §, sprint story/AC, constitution principle) |
| `NFR-<N>.<k>` | Non-functional requirement | One MUST statement for a quality (performance, security, reliability, accessibility, data integrity), testable, with a **Source**. Story-level FR and NFR rows from Story requirements mode keep their IDs; start the spec from them and do not renumber |
| `AC-<N>.<k>` | Acceptance criterion | Given/When/Then, per the `deliver-acceptance-criteria` skill; names the sprint-plan AC it refines (`S3-1/2` = story S3-1, 2nd bullet) and the FRs it covers |
| `EC-<N>.<k>` | Edge case | Per the `deliver-edge-cases` skill categories; expected behaviour comes from a source or is an open item |
| `TC-<N>.<k>` | Test case | Type, test file, exact input and expected output; **Covers** lists FR/AC/EC IDs |
| `Q<k>` / `A<k>` / `D<k>` / `C<k>` | Clarification / Assumption / Decision / Conflict | Section 9 only |

Use the `speckit-specify` skill for sections 1-2 (user scenarios, testable requirements, success criteria, the 3-question clarification limit and its quality checklist). Ignore its branch, `specs/` directory, template resolution, hooks and file writes; and where it says "no implementation details", that applies to sections 1-2 only. Sections 3-7 are the engineering layer it leaves out.

## Who decides what

| The question is about | Answered by a source? | You write |
|---|---|---|
| Behaviour a user or player can observe (vocabulary, accepted inputs, messages, limits, aliases, scope) | Yes | FR with that source |
| — same — | No, and it changes scope, UX or security | `Q<k>` `[NEEDS CLARIFICATION]` (max 3, highest impact first) |
| — same — | No, and a safe default exists | `A<k>` ASSUMPTION: the default, why, and what changes if wrong. The FR cites `A<k>` as its source |
| Internal engineering (algorithm, helper layout inside **Touches**, test structure) | — | `D<k>` DECISION with one-line rationale |
| Two sources disagree (PRD vs plan vs constitution) | — | `C<k>` CONFLICT quoting both; neither side is applied silently |

Every `Q`, `C` and product `A` also goes in the **Gaps** list you return, so the caller can put it to the user. Order the Gaps by impact: `C` first, then `Q`, then `A` (scope > security > UX > wording).

**Facts about existing code are not Gaps.** When the code is not available to you (field names, file layout, an existing convention), write `D<k>` "assume X; verify against `<file>` and follow the code if it differs". The engineer settles it by reading the code; the user is never asked.

**Product gaps are never decided in the spec.** No exceptions:
- Not "it is obviously the common spelling"
- Not "aliases make the parser friendlier"
- Not "the engineer needs an answer now"
- Not by labelling it "Product decision" or `D<k>`

| Excuse | Reality |
|---|---|
| "The engineer must not have to ask questions" | An `A<k>` gives them a default to build against *and* lets the user overrule it before code is written |
| "Extra accepted inputs are harmless" | They are scope. Every alias needs tests, and another writer will choose different ones |
| "The constitution and PRD obviously mean X" | Then the user confirms it in one line. Write `C<k>` |

## Boundaries

- Files: only paths inside the sprint's `**Touches:**` (or the files its stories name). A needed file outside them is a `C<k>`.
- Interfaces: reuse the dependency sprints' names and types exactly; read the code if it exists.
- The spec never tells the engineer to edit the sprint plan or its status markers; `sprintkit-sync` owns them.

## Before returning

Run the checker on the spec file, per the `tracing-spec-coverage` skill, and fix every finding with Edit. The spec file is the only file you write (the path the caller gave you); no temporary files.

Return: `Constitution: v<version> read` (or `none`), a short report (spec path, Status, checker result, counts of FR, AC, EC and TC; not the spec text), then **Gaps**: each `Q`, `A` and `C` as a one-sentence question the user can answer.
