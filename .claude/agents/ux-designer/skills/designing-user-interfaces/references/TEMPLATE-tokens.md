# Design tokens

**Status:** draft  **Styling layer:** <from the constitution, e.g. Tailwind theme and CSS variables>  **Themes:** <dark | light | both>

Tiers: primitive (raw values) -> semantic (meaning) -> component (use). Screens and components refer to semantic and component tokens only.

Under a component library (for example daisyUI), the semantic tier uses the library's own token names and theme variables rather than invented ones, and "Mapping to the stack" below is its theme block.

## Colour

| Tier | Token | Value | Role | Basis |
|---|---|---|---|---|

### Contrast pairs

| Foreground | Background | Use | Target | Result |
|---|---|---|---|---|
| | | | AA 4.5:1 | UNVERIFIED |

## Type

| Token | Size / line height / weight | Use |
|---|---|---|

Display size is at least 2.5x body. Figures use tabular numerals.

## Spacing, radius, borders

4px rhythm table.

## Motion

| Token | Duration / easing | Use | Reduced-motion behaviour |
|---|---|---|---|

## Chart colours

Series and up/down colours with the non-colour cue for each.

## Mapping to the stack

How each semantic token becomes a CSS variable and a utility in the styling layer named above.
