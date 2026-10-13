---
name: exploratory-testing
description: Use when scripted test cases are exhausted but a feature's actual risk hasn't been fully probed - unscripted, simultaneous learning and testing to find what the acceptance criteria didn't anticipate
---

# Exploratory Testing

## Overview

Scripted test cases (`../test-case-design/SKILL.md`) verify what's already been thought of. Exploratory testing finds what wasn't — it's simultaneous learning, test design, and execution, driven by what the last action revealed rather than a pre-written script.

Exploratory testing is a deliberate technique with structure, not "clicking around randomly" — it still needs a charter, needs to be time-boxed, and needs its findings reported the same way scripted findings are.

## When to Use

- After scripted acceptance/case-based testing is complete, to probe for what the criteria didn't anticipate
- A feature is new or high-risk and the full shape of its failure modes isn't yet known
- Investigating a vague bug report ("sometimes trading feels off") that doesn't name a specific reproducible scenario yet

## Method: Session-Based Testing

1. **Charter** — state the mission in one sentence before starting: "explore the confirm/reject flow for ways a trade could execute without explicit confirmation" is a charter; "test the trading page" is not specific enough to know when you're done.
2. **Time-box** — 30-90 minutes per session is typical; longer sessions lose focus and produce diminishing findings per minute.
3. **Explore and note** — try unexpected input combinations, interrupt a flow mid-way (close a dialog, navigate away, double-click a submit button), combine features in ways a script wouldn't ("add a ticker to the watchlist while a chat proposal for it is pending"), and vary timing (fast repeated actions, long idle periods).
4. **Follow interesting threads** — if an action produces a surprising result, dig deeper into that area rather than moving on per a fixed script. This is exploratory testing's main advantage over scripted testing: it adapts to what it just learned.
5. **Record as you go** — every anomaly, even one that seems minor or you're not sure is a real bug, with enough detail to reproduce it later. An exploratory finding not written down is a finding that didn't happen.

## What to Specifically Try

- **Boundary combinations the script didn't think of**: two near-simultaneous actions on the same resource, a value at exactly a stated limit combined with another edge condition.
- **Interruption**: back button, browser refresh mid-submit, closing a modal instead of using its buttons, network disconnection mid-request.
- **Unexpected sequencing**: performing steps out of the order a happy-path script assumes (confirming a proposal, then trying to reject the same one; reloading mid-flow).
- **Data that's unusual but not technically invalid**: very long strings, Unicode/emoji in text fields, a ticker symbol that exists but has no price yet, a position reduced to a fractional share near zero.
- **Cross-feature interaction**: does unwatching a ticker while a chat explanation for it is in flight break anything (constitution FR-26: unwatching must not change the position)?

## Reporting

Each finding gets the same defect-report rigor as a scripted-test defect (see `../defect-triage/SKILL.md`): what you did, what happened, what you expected, severity. "I was exploring and X seemed broken" is not a report; "steps 1-4, then this happened, expected this instead" is.

## When Exploratory Testing Is Not a Substitute

Exploratory testing complements scripted coverage; it doesn't replace it. A feature with no acceptance-criteria-based tests and only exploratory notes has no regression protection — anything found exploratory must still get captured as an automated regression test (see `../regression-testing/SKILL.md`) once reproduced, or it will silently reappear.

## Common Mistakes

| Mistake | Fix |
|---|---| 
| No charter, just "try things" | State the specific mission before starting, so you know what "done" looks like |
| Findings only in your head, written up after the session from memory | Record immediately, with enough detail to reproduce |
| Treating exploratory notes as the final regression safety net | Convert reproduced findings into automated tests |
| Session runs for hours with no time-box | Time-box 30-90 minutes; start a fresh charter for a new area |

## Quick Reference

| Step | Action |
|---|---|
| Before | Write a one-sentence charter, set a time-box |
| During | Vary input, timing, sequencing, interruption; follow surprising results |
| On a finding | Record immediately: steps, actual, expected |
| After | Report findings via `../defect-triage/SKILL.md`; convert real defects into automated regression tests |
