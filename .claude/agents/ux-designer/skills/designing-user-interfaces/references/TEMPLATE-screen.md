# S<NN> <Screen name>

**Status:** draft  **FRs:** <FR-x, FR-y>  **Constitution:** <principle numbers that shape this screen, or none>  **Decisions:** <UXD-n, UXD-m>

## 1. Purpose

Who uses this screen, what they decide or do here, and what a good outcome looks like. Two to four lines.

## 2. Wireframe

Desktop (<width>):

```text
+---------------------------+
| REGION A                  |
+-------------+-------------+
| REGION B    | REGION C    |
+-------------+-------------+
```

Narrow (<width>):

```text
(regions stacked, in this order)
```

## 3. Regions and components

| Region | Contents | Data shown (source field) | FR | Notes |
|---|---|---|---|---|

Every figure shown names the backend field it comes from. The interface does no arithmetic of its own unless the constitution allows it.

### States

| Region / component | Default | Loading | Empty | Error | Stale / offline | Disabled | Selected | Notes |
|---|---|---|---|---|---|---|---|---|

Each cell says what the user sees, in words. Use `n/a` only when the state cannot occur and say why.

### Interactive elements

| Element | Hover | Focus | Active | Disabled | Loading | Error | Selected |
|---|---|---|---|---|---|---|---|

## 4. Interactions

Numbered steps for each task on this screen: user action, system response, what changes on screen, how failure shows.

## 5. Copy

| Where | Text | Why this wording |
|---|---|---|

Quote standing labels from the constitution or PRD exactly.

## 6. Responsive and accessibility

Layout changes by width; keyboard order; names, roles and live-region behaviour for dynamic content; colour-independent cues for each status.

## 7. Rationale

- **Who and what leads.** <why the eye lands where it does; cite UXD-n or FR-x>
- **Why the regions sit where they do.** <the need served and the layout rejected>
- **What was left out, and why.** <scope or PRD basis>
- **Rules that shaped it.** <constitution principles and doctrine rules, each tied to a visible element>
- **Trade-offs.** <what this screen gives up and for whom>

## 8. Open items

`Q<k>` references to README.md, and anything `UNVERIFIED`.
