---
name: sprintkit-design
description: Use when a sprintkit track has a sprint plan but no UI design for the sprints about to be built, when the user asks to design screens, wireframes, the design system or tokens for a sprint, says "design the UI", "design sprint N", "what should this look like", "wireframe the screens", "design the next sprint's screens", or when an implementer is about to build a UI story with nothing in planning/ux/ to build against. Also use when existing design in planning/ux/ must be extended to further sprints or revised after owner feedback, or when the track has no system architecture document yet.
---

# Sprintkit Design

The design stage between `sprintkit-plan` and the build. It dispatches `ux-designer` to fill `planning/ux/` so an implementer has screens to build against, one sprint slice at a time, and dispatches `solution-architect` once per track to fill `planning/architecture/` with the system design.

You are a **stage controller**. You do not design: you resolve which sprints to design, brief the agents, record design status on the plan, and relay their Gaps to the user. The agents write every file in `planning/ux/` and `planning/architecture/` respectively.

**Both agents read requirements through their user stories, never bare IDs — but at a depth, and from a source, that matches what each decides.** A requirement line is terse by design; the story it was drawn from ("As a X, I want Y, so that Z") carries the intent the line strips out. `ux-designer` gets this at the slice's grain and from the PRD itself: the sprint plan only picks *which* slice to design; the story text, its epic and its FR/NFR rows are pulled from the PRD's own §5/§6, filtered to the stories in this slice that are actually UI-relevant (a mixed sprint's backend stories are left out of the brief, not just left undesigned). `solution-architect` gets it at the system's grain: the NFRs that drive a hosting and software-architecture decision (throughput, availability, data integrity, security), each with its basis, plus the PRD's epics at summary level for what the system has to support — **not every FR in the PRD with its story pasted in.** A whole-PRD FR-by-FR brief overloads the one dispatch that runs once per track with detail a hosting decision doesn't need; keep it to what section 1 (NFR baseline) and section 0 (summary) of its own template actually ask for.

**The dispatch is the middle of your job, not the end of it.** When an agent returns with its design written, the stage is not finished: the UX side still needs its `**Design:**` lines (step 4) and the architecture side needs its one-time status recorded, and only you can do either. An agent's closing report reads conclusively and the design looks complete, which is exactly when this stage gets abandoned one step early.

**Binding is advisory.** `planning/ux/` and `planning/architecture/` are the design of record and `sprintkit-implement` is pointed at both, but code that diverges fails nothing. Do not edit `planning/plan` acceptance criteria, specs, `docs/adr/`, or `sprintkit-review`'s blocker rules to enforce either.

## Args

| Args | Designs |
|---|---|
| `track:<name>` | Track only. Asks once which sprints to design; suggests `next`. |
| `track:default screens:2` | Sprint 2's screens. |
| `track:default screens:2,3` | Exactly those sprints. |
| `track:default screens:next` | Every non-`[DONE]` sprint with UI stories, no design yet, whose dependencies are `[DONE]` or in the same batch. |
| `track:default screens:all` | Every non-`[DONE]` sprint with UI stories. |
| `track:default revise` | Revise mode: fold the owner's feedback into existing files. |
| `track:default architecture` | Architecture only: run or revise the one system design in `planning/architecture/`. Does not touch `planning/ux/` or any `**Design:**` line. |

A bare `track:<name>` with no `screens:`/`architecture:` token runs both: the architecture dispatch first (see below), then the UX slice selection. Either can be invoked alone with its own token.

Track resolution is the same convention as the rest of the pipeline: `default` → `planning/sprint.md`, `<name>` → `planning/<name>-sprint.md`. One track, use it; several, ask; none, suggest `/sprintkit-plan`.

## Session file and constitution

Before any other work, switch to the track branch `sprintkit/<track>` (never work on `main`) and read the track's session file per [.claude/sprintkit/SESSION.md](../../sprintkit/SESSION.md): resume from its Step if active, and update it before every pause or stop. As a subagent, read it but do not write it.

Read `planning/constitution.md` if it exists and follow [.claude/sprintkit/CONSTITUTION.md](../../sprintkit/CONSTITUTION.md). Every brief you write includes that file's brief line verbatim; the `constitution-gate` hook blocks dispatches that omit it. The MUST rules that touch the UI become acceptance points on the screens they shape — tell the agent which ones you expect to apply, and let it find the rest.

## The two kinds of run

The distinction is the whole skill. Getting it wrong produces one design silo per sprint.

| | **System run** (first run on a track) | **Slice run** (every run after) |
|---|---|---|
| Decides | Users, information architecture, flows, **the page shell and every region later sprints will fill**, tokens, component set | Only the screens and regions this slice's stories need |
| Writes | `ux-design.md`, `design-tokens.md`, `decisions.md`, `README.md`, plus the selected sprints' screens | Adds screens to `screens/`, extends `decisions.md` and the `README.md` status table |
| Re-decides | — | **Nothing from the system run.** A token or shell change is a `[USER]` Gap, not a quiet edit |

**The page shell belongs to the system run, including regions no sprint has built yet.** A page cannot be laid out in fragments: if each slice invents its own shell, Sprint 6 inherits a layout designed without knowing a chat panel was coming. The system run places every region the plan implies and marks the unbuilt ones as reserved, with the sprint that fills each. A slice run designs *inside* its own regions and leaves the rest alone.

## The architecture run

Unlike UX, there is no per-sprint slicing on the architecture side: `solution-architect` runs **once per track**, covers the whole system, and is re-dispatched in full (not extended slice by slice) only when the PRD, the sprint plan's technical context, or a later Revise request changes something it already decided.

**The ask is narrow: propose a design suitable to host this application, including the software architecture.** Not a review of every requirement — a hosting and structure proposal, sized to what the system actually is. The brief gives the agent what a hosting decision needs (the NFR baseline, the deployment target, the epics at summary level) and lets its own template's required sections do the rest. See "Brief the agents" below for exactly what goes in, and what deliberately stays out.

**This project has no cloud deployment.** Brief the agent with the real target: a single Docker container on `127.0.0.1`, FastAPI backend, Next.js static export, SQLite, no cloud account. `designing-system-architecture`'s own fallback for this case is "for a local or single-host target, draw the host, container network, ports and volumes instead" — tell the agent to take that path rather than filling the cloud-topology sections with sized-for-nothing boilerplate. Its resource inventory, software architecture, trade-off matrix and ADRs still apply; its subnet CIDRs, availability-zone placement and cloud cost tables do not, and the design should say so once rather than mark each one `N/A`.

**Section 3.2, Software architecture, is REQUIRED in the agent's own template and is not optional here.** It is the layering, the module boundaries, the service APIs and the data model — the part of the design an implementer actually builds against, as distinct from where the container runs. A design that stops at the host diagram and skips 3.2 is incomplete; say so explicitly in the brief rather than relying on the agent to notice its own template says REQUIRED.

**ADRs already exist as a separate, narrower mechanism — do not duplicate them.** The constitution's Development Workflow and several sprint specs already require specific files under `docs/adr/` (for example `docs/adr/0001-money-representation.md`, required by Sprint 1's spec). Those are small, single-decision records owned by whichever sprint's spec names them. `solution-architect`'s own section 7 is for architecture-level decisions costly to reverse at the system level (the deployment shape, the market-data interface boundary, the SQLite-vs-something-else choice) — not a second home for a decision a spec already pins to a `docs/adr/` file. Brief the agent with the `docs/adr/` files that already exist or are already required, so it cites them rather than re-deciding or re-writing them.

## Deliverables

The canonical set from `designing-user-interfaces`, and **nothing else**:

```
planning/ux/README.md            index, per-sprint status table, Gaps, Verification still to run
planning/ux/ux-design.md         users, IA, flows, screen inventory, shell, design-system summary
planning/ux/screens/S<NN>-<slug>.md   one file per screen
planning/ux/decisions.md         UXD-<n>, Status Proposed until the owner rules
planning/ux/design-tokens.md     tokens by tier, mapped to the stack
```

Named track: `planning/ux/<track>/` with the same files.

**Never a per-sprint design document.** No `sprint-N-design.md`, no `sprint-N/` directory, no per-sprint tokens file. A sprint's screens are *added to* `screens/`; its decisions are *appended to* `decisions.md`. Say so in the brief — the natural pull of a per-sprint stage is a per-sprint file, and a monolith that duplicates the canonical files is the failure this rule exists to prevent. If a brief would produce one, the slice is wrong, not the layout.

**Architecture side**, one file, filled from `designing-system-architecture`'s template:

```
planning/architecture/design.md    the filled TEMPLATE.md: NFR baseline, topology, resource inventory,
                                    software architecture, traffic matrix, ADRs, Gaps
```

Named track: `planning/architecture/<track>-design.md`. **Never per-sprint**, for the same reason as the UX side: a system design re-decided piecemeal per sprint stops being one system design.

## Design status is recorded in two places

A selector cannot read prose. `screens:next` needs machine-readable status, so every run records it twice:

1. **On the sprint, in the Sprint file** — a `**Design:**` line beside `**Spec:**`, in exactly this form:

   ```
   **Design:** `planning/ux/screens/S01-watchlist-page.md`, `planning/ux/screens/S02-trade-ticket.md`
   **Design:** not needed (no UI stories)
   **Design:** not designed yet
   ```

   This is the only edit this skill makes to the Sprint file. Never change a sprint's status marker, stories, acceptance criteria, dependencies or `Touches:`, and never touch a `[DONE]` sprint's section.

2. **In `planning/ux/README.md`** — a status table row per sprint:

   | Sprint | UI stories | Screens | Decisions | Status |
   |---|---|---|---|---|
   | Sprint 2 | US-1, US-2, US-3, US-4, US-5 | S01 | UXD-1 to UXD-8 | designed, owner not yet vetted |
   | Sprint 3 | US-8, US-10 | — | — | not designed yet |

**Architecture status is track-level, not per-sprint.** Record it once, in `planning/architecture/design.md`'s own `**Status:**` line (`draft` | `ready` | `owner not yet vetted`) — there is no sprint file edit on this side, since the design is not sliced by sprint.

## Process

### 1. Read the plan and resolve the scope

Read the Sprint file, the PRD, `planning/ux/` and `planning/architecture/`, whichever exist.

**Architecture scope:** if `planning/architecture/design.md` (or `<track>-design.md`) does not exist, or `architecture` is in args, that side runs this invocation (step 2a). If it already exists and `architecture` was not requested, skip it and say so in one line.

**UX scope — two filters, not one.** First, which *sprints* are in play: for each sprint decide whether it has at least one **UI story** — a story whose `Touches:` names frontend paths, or whose acceptance criteria describe something a user sees. A sprint with none gets `**Design:** not needed (no UI stories)` and is never selected. Second, once a sprint is selected: a mixed sprint (an API story and a UI story together) still has non-UI stories in it. **Filter to the UI-relevant stories only** — those are what you brief the agent with in step 3, not the sprint's full story list. A backend story in a selected sprint contributes nothing to the screen inventory and is left out of the brief.

Take the sprints from `screens:`. Without a selector, list each sprint as designed, not designed, `not needed`, or `[DONE]` (skipped), and ask once; suggest `next`. As a subagent, design every non-`[DONE]` sprint with UI stories and no design. If `architecture:` was the only token given, skip the UX side entirely.

### 2. Reconcile what exists

**2a. Architecture.** If `planning/architecture/design.md` already exists, this is a revision, not a first run: read the brief rules — if the request is `architecture` with no further detail and the file's `**Status:**` is already `ready`, ask whether this is a Revise (owner feedback to fold in) or a redesign (something in the PRD or sprint plan's technical context changed) rather than silently redoing it. If it does not exist, this is the first run; proceed to step 3 for the architecture dispatch.

**2b. UX.** If `planning/ux/` already holds files, this is a slice run. Before dispatching, run this as a **file-list diff, not a content judgment**:

1. List every file under `planning/ux/` (and `planning/ux/<track>/` for a named track).
2. Every one must be `README.md`, `ux-design.md`, `decisions.md`, `design-tokens.md`, or `screens/S<NN>-<slug>.md` — the five names in Deliverables, nothing else.
3. Anything not on that list **is a mismatch, regardless of whether you read it and found its content agrees with the canonical files.** Agreement is not the test; the filename is. A file that says the same thing as `ux-design.md` is still not `ux-design.md`.
4. Separately, check that the README's status table matches the Sprint file's `**Design:**` lines, and that every `**Design:**` line names a file that exists.

**A mismatch is reported, never accommodated — "it's consistent with the structured files" is not a resolution, it is the failure mode this step exists to catch.** Stop before dispatching and tell the user what you found and the two ways out (fold it into the canonical set, or delete it). Do not add a note to the README pointing at the stray file and continue designing — that leaves two sources of truth and, left alone, invites the next run to add a third (`sprint-N-design.md` for the next sprint, following the pattern the first one set). The same rule applies to `planning/architecture/`: a second file there is a mismatch on sight, regardless of content.

### 3. Brief the agents

**`ux-designer`** (`subagent_type: "ux-designer"`), one dispatch per UX run, in Design mode. **The sprint plan picks which slice to design; the PRD is what the design is drawn from.** The sprint file only identifies story IDs and the sprint's `Touches:` — pull the actual story text, the epic it sits under, and its FR/NFR rows from the PRD itself (§5 epics, §6 requirements), not from the sprint file's embedded copies. The sprint file can be edited after a merge (`sprintkit-sync` folds in review outcomes) in ways that leave its copy of a story stale against the PRD; the PRD is the one both sides are supposed to agree with. The brief names:

- the constitution brief line, verbatim, first;
- the PRD path as the source of the design, and the Sprint file path only to say which sprint numbers and story IDs are in this slice;
- **the UI-relevant story IDs in this slice, filtered per step 1** (non-UI stories in a mixed sprint are left out), each with its full story text (`As a <persona>, I want <action>, so that <benefit>`) **as the PRD states it**, and the epic it belongs to;
- whether this is the system run or a slice run, and for a slice run, which regions of the shell it owns and which belong to other sprints;
- the screen inventory you expect, **derived from the filtered stories** — one screen per place a user goes to do one of those stories, not one per sprint. A five-story sprint on one page is one screen; a two-story sprint across a list and a detail view is two. Tell the agent to say in `ux-design.md` why the inventory splits where it does;
- the FR and NFR IDs the filtered stories carry, **from the PRD's §6/§7, with their story text**, so each screen can trace to both;
- the constitution principles you expect to shape these screens;
- that it writes only the canonical files, and for a slice run, that it must not re-decide tokens, IA or the shell.

For Revise mode, pass the owner's feedback verbatim and the files it touches; the agent edits in place and marks superseded decisions rather than deleting them.

**`solution-architect`** (`subagent_type: "solution-architect"`), once per track, in Design mode (or Review mode for a revision of an existing `ready` design). **Keep this brief short — it is one dispatch for the whole system, not a sprint slice, and it does not need the PRD's full requirement list to do its job.** The brief names:

- the constitution brief line, verbatim, first;
- the task in one sentence: propose a design suitable to host this application, including the software architecture;
- the PRD's **NFR table (§7) in full** — throughput, availability, data integrity, security, accessibility — since these are what a hosting and structure decision is actually sized against, each kept with its basis;
- the PRD's **epics at summary level** (§5 titles and one line each), not the FR list under them — enough for the agent to know what the system supports, without asking it to trace every FR individually. A specific FR only goes in if it fixes something about the deployment or data shape itself (for example FR-15's quantity/rounding rule, since it shapes the money-handling boundary, not the UI);
- the real target: single Docker container, `127.0.0.1` only, FastAPI, Next.js static export, SQLite, no cloud account — so it takes the local/single-host path in its own template rather than filling cloud-topology sections for an account that doesn't exist;
- that **section 3.2, Software architecture, is required** — layering, module boundaries, service APIs, data model — not just the host/container diagram;
- the `docs/adr/` files that already exist or that a sprint spec already requires (name them), so it cites rather than re-decides those, and reserves its own section 7 for system-level decisions no spec already owns;
- that it writes to `planning/architecture/design.md` (or `<track>-design.md`), its own template, nothing else.

### 4. Record status

**This is yours, and the agents cannot do it for you.** `ux-designer` may write only under `planning/ux/`; `solution-architect` does not write files at all — the caller saves its output. Skipping this step is how `screens:next` ends up with nothing to read, and how an architecture design the agent returned is lost because nobody saved it. Do it as soon as each agent returns, before relaying Gaps.

**UX side:** for every sprint in this run, edit its section in the Sprint file to carry a `**Design:**` line beside `**Spec:**`, in the form pinned above. Then, for every sprint *not* in this run that has no `**Design:**` line yet, add `**Design:** not designed yet` or `**Design:** not needed (no UI stories)` so the next run's selector sees the whole plan. Never touch a `[DONE]` sprint's section. Then open `planning/ux/README.md` and check its status table agrees with the lines you just wrote; if they disagree, the README is wrong — fix the table.

**Architecture side:** `solution-architect` returns the filled template as its result; you save it to `planning/architecture/design.md` (or `<track>-design.md`), with the agent's own `**Status:**` line from the template's header (`draft` until the owner vets it).

### 5. Relay Gaps

Each agent returns a summary plus Gaps tagged `[PM]` or `[USER]`. Put every Gap to the user in **one** message, grouped by agent and then by sprint, conflicts first. `[PM]` Gaps the PRD answers: answer them from the PRD and say so. Anything the PRD cannot answer goes to the user with the agent's stated assumption (`ASSUMPTION A<k>`) so the design stays complete meanwhile.

### 6. Report

One line per sprint designed: screens written, decisions added, Gaps open. One line for the architecture run, if it ran: file written, ADR count, Gaps open. Then the owner's next step: read `planning/ux/README.md` in its reading order and set each `Proposed` UXD to `Accepted` or `Rejected`; read `planning/architecture/design.md` section 7 and do the same for its ADRs. **Decisions stay `Proposed` until the owner rules — you never accept one on the owner's behalf**, and neither does an agent.

Tell the user that `planning/ux/**` publishes to Confluence through `sprintkit-jira` (`scope:docs`) when Confluence is configured, into the "User Interface Design" folder (`confluence.folders.ux`), and that `planning/architecture/design.md` publishes through the same scope as the `architecture` document type into the "Architecture Design" folder (`confluence.folders.architecture`). `sprintkit-jira`'s separate `adr` type still publishes individual Nygard-shaped files under `docs/adr/`; it is not the system-design file.

## Where this sits

```
sprintkit-start → sprintkit-plan → sprintkit-design → sprintkit-graph → sprintkit-autopilot → sprintkit-retro
```

Run it after the specs for a sprint are approved and before that sprint is built, so the implementer has screens and a system design. It does not block the build: a sprint with `**Design:** not designed yet` still builds, with the UI unspecified; a track with no `planning/architecture/` still builds, with the system design implicit in the code.

## Common mistakes

| Mistake | Fix |
|---|---|
| Stopping when an agent's design lands | The stage ends at step 6. No `**Design:**` line, or an unsaved architecture result, means the next run has nothing to read |
| `planning/ux/sprint-2-design.md` | Screens go in `screens/`, decisions in `decisions.md`. Never a per-sprint document |
| Scope stated only in README prose | A `**Design:**` line on the sprint and a status row. `screens:next` cannot read prose |
| A slice run re-decides tokens or the shell | Only the system run decides those. A change is a `[USER]` Gap |
| Designing another sprint's regions "to settle them" | The system run reserved them. Design inside your own |
| "The stray file is consistent with the canonical ones, so it's fine" | Agreement is not the test; the filename is. Not on the five-name list means stop, every time |
| Finding stray design and noting it in the README | Report the mismatch and stop. Two sources of truth is the bug |
| One screen per sprint by default | Inventory comes from the stories; say why it splits where it does |
| Marking a decision or ADR `Accepted` | Only the project owner does that |
| Editing specs, `docs/adr/`, or review rules so code must match the design | Binding is advisory on both sides |
| Claiming a contrast ratio, a WCAG pass, or a cited price/benchmark | The agents have no browser or live pricing page. `UNVERIFIED` / `ASSUMPTION A<k>` and a Verification row |
| Briefing `ux-designer` with bare FR/NFR IDs | Pair every ID the slice carries with the story text it was drawn from |
| Briefing `ux-designer` with the sprint's full story list, or the sprint file's copy of a story | Filter to the UI-relevant stories only; pull the text, epic and FR/NFR rows from the PRD, not the sprint file |
| Briefing `solution-architect` with every FR in the PRD and its story text | One dispatch for the whole system does not need the sprint-level detail. NFRs, epics at summary level, and only the FRs that shape deployment or data |
| Running the full cloud-topology template for a single-container app | Brief the real target; take the local/single-host path, say once why the rest doesn't apply |
| A new ADR in `planning/architecture/design.md` for something a sprint spec already owns in `docs/adr/` | Cite the existing file; section 7 is for system-level decisions no spec already pins |
