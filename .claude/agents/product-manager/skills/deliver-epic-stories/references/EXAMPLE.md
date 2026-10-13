---
artifact: epic
version: "1.0"
created: 2026-10-04
status: draft
---

# Epic: AI-proposed trades with explicit confirmation

## Epic Summary

The user chats with the AI assistant about their portfolio. When the AI suggests a trade, it shows a proposal with its explanation, and nothing executes until the user clicks Confirm.

## Objective

Let beginners learn from AI suggestions while keeping every trade a deliberate user decision.

## Benefits

- Learning: each suggestion arrives with a plain-language reason.
- Safety: no AI-originated trade can run without a click.
- Trust: figures quoted by the AI come from the backend, not from the model.

## User Stories/Features

- [US-101] - As a beginner trader, I want the AI to explain a suggested trade, so that I understand why it is proposed.
- [US-102] - As a beginner trader, I want to confirm or reject a proposal with one click, so that I stay in control.
- [US-103] - As a beginner trader, I want proposals to expire, so that I never confirm a trade at a stale price by accident.

## Mockups/Designs

- planning/ux/ (chat panel and proposal card)

## Dependencies

- Shared trade validation and execution path (manual trades).
- Price source label (simulated or live) available to the chat context.

## Timeframe

Start Date: TBD (sprint plan)

End Date: TBD (sprint plan)

## Stakeholders

- Project owner (approves scope)
- Beginner trader (primary user)

## Notes/Additional Information

Traces to the PRD guardrail that no AI trade executes without Confirm. Out of scope: AI-initiated watchlist changes.
