---
name: agent-regression-evaluation
description: Use when a change to an agent prompt, SKILL.md file, or tool configuration needs evaluation against explicit expected outcomes rather than a subjective "seems better" impression
---

# Agent Regression Evaluation

## Overview

This repository's own `.claude/agents/` definitions are software — a prompt edit, a skill rewrite, or a routing change can regress behavior the same way an application code change can. This skill applies the same discipline this agent applies to application code to the agents/skills themselves: explicit expected outcomes, evidence, no "it seems better."

## When to Use

- An agent's `.md` definition or `description` frontmatter changed
- A `SKILL.md` file was edited or rewritten
- A tool permission list, routing rule, or dispatch pattern changed
- Deciding whether an agent/skill change caused a behavioral regression before it merges

## Why This Needs Explicit Cases, Not Impressions

"The agent seems more careful now" is not verifiable and does not survive the next edit. An evaluation case states: given this input, the agent should (or should not) do X — the same shape as a test case for application code, applied to a prompt instead of a function.

## Building an Evaluation Case

```
Case ID
Target: which agent/skill changed
Scenario: the exact prompt/dispatch given to the agent
Expected behavior: specific, observable (did it ask a required clarifying question, did it refuse an out-of-scope action, did it cite the right skill, did it stay within its role boundary)
Pressure (if testing a discipline-enforcing skill): time pressure, authority pressure, sunk-cost framing — see `../../shared-skills/test-driven-development/SKILL.md`'s own "Common Rationalizations" table for the shape of pressure scenarios this repo already uses
Actual behavior: what the agent (with the change applied) actually did
Verdict: Pass / Fail / Regression (passed before, fails now) / Improvement (failed before, passes now)
```

## Baseline-Before-Change Discipline

To call something a regression, you need the **before** behavior, not an assumption about what it "probably" did. If no baseline run exists for the case:

1. Run the scenario against the pre-change version (prior commit, or the unmodified file) first.
2. Record that result.
3. Only then run it against the changed version and compare.

Skipping step 1 and asserting "this used to work differently" without having actually run the prior version is the agent-evaluation equivalent of claiming a bug fix without reproducing the original bug first (see `../../shared-skills/verification-before-completion/SKILL.md`'s Regression test pattern — the same red-green discipline applies here, just with an agent invocation standing in for a function call).

## What to Target

- **Role boundary changes**: does the agent now overreach into another agent's territory, or wrongly refuse something it should do? (This repo's agents each define an explicit boundary section — a prompt edit that blurs it is a regression even if no test "fails" in the traditional sense.)
- **Discipline-enforcing skill edits** (Iron Law skills like `test-driven-development`, `systematic-debugging`, this skill library's own `../defect-triage/SKILL.md`): re-run under the pressure scenarios the skill's own rationalization table anticipates — does the edited wording still hold under the same pressure that originally motivated the rule?
- **Routing/description changes**: does a dispatcher still pick the right agent/skill for the same request after a `description` field edit? A description rewrite that drops a trigger keyword can silently stop the right skill from loading.
- **Reference/technique skill edits** (API docs, checklists): does the edited skill still answer the retrieval scenarios it's supposed to cover?

## Output

A short table: case ID, target, scenario, expected, actual, verdict. Any `Regression` verdict is a defect per `../defect-triage/SKILL.md`, routed back to whoever authored the agent/skill change — this agent does not rewrite another agent's prompt itself, the same way it doesn't patch application code.

## Common Mistakes

| Mistake | Fix |
|---|---|
| "The new wording reads better" as the entire evaluation | Needs an explicit scenario + expected outcome, not a prose impression |
| Calling something a regression without having run the prior version | Baseline first, compare second |
| Testing only the happy path of a routing change | Include a case that should NOT trigger the agent/skill, to catch over-broad triggering |
| Treating a discipline skill's wording change as safe because "the rule itself didn't change" | Micro-test the wording — this repo's own `superpowers:writing-skills` found that wording alone can change compliance under pressure even when the rule is unchanged |

## Quick Reference

| Changed | Evaluate for |
|---|---|
| Role boundary / overlapping-responsibilities section | Does the agent still refuse/accept the same out-of-scope requests? |
| Discipline-enforcing skill (Iron Law style) | Re-run its own rationalization-table pressure scenarios |
| `description` frontmatter | Does routing still pick the right agent for the same trigger phrases? |
| Reference/checklist skill | Do retrieval scenarios still find the right section? |
