# UI craft rules

## Contents

- Read the product first
- Typography
- Colour
- Spacing and layout
- Surfaces
- Motion
- Accessibility
- Responsive and native
- Common giveaways

## Read the product first

Take values from the code, not from memory: the theme or token file (`theme.ts`,
`tokens.css`, `tailwind.config.*`, a design-system package), the global stylesheet, and
the sibling components. Lift exact values: colours, the spacing scale, font stacks,
radii. Name the one styling approach the repo uses (Tailwind, CSS modules, styled
components, `StyleSheet`) and write in it; never mix in a second.

## Typography

- One type scale, from the product. In a new system, pick four or five sizes and keep
  them.
- One text style per role inside a card or row, with hierarchy from order and weight. More
  than three styles in a small block is noise.
- Body text 15 to 17px on screens, line height 1.4 to 1.6, line length 60 to 75
  characters.
- Numbers that line up in tables and counters use tabular figures
  (`font-variant-numeric: tabular-nums`).
- Avoid the reflex font choice for a new direction (the default system UI stack or the
  first font a generator reaches for) unless the product already uses it.

## Colour

- Use the product's tokens. A new colour needs a token, not a hex literal in a component.
- In a new system, define colours in OKLCH so lightness steps are even, and derive
  hover, pressed, and disabled states from one base by lightness.
- One accent colour, used for the primary action and focus, not for decoration.
- Dark mode is its own palette: lower contrast between surfaces, no pure black or pure
  white text on large areas.

## Spacing and layout

- One spacing scale (for example 4, 8, 12, 16, 24, 32). The outer padding of a container
  defaults to the gap between its children.
- Width comes from a shared container token, taken from a sibling page when one exists.
- Stacking order uses named layers (base, sticky, overlay, modal, toast), not ad hoc
  `z-index` numbers. A banner that must sit behind a composer is a layer decision.

## Surfaces

- Separate surfaces one way, consistently: a background step, a border, or a shadow.
  Mixing all three on one card is the default look to avoid.
- Corner radius follows nesting: an inner element's radius is the outer radius minus the
  padding between them.

## Motion

- Animate `transform` and `opacity` only. Durations: 120 to 200ms for small state
  changes, 200 to 320ms for things entering, faster out than in.
- Ease out for entering, ease in for leaving; no linear easing on UI elements.
- No motion for keyboard-triggered actions or for anything used constantly.
- Respect `prefers-reduced-motion` (and the platform's reduce-motion setting on native).
- Fix stutter or jumps before changing speed.

## Accessibility

- Text contrast at least 4.5:1, large text and icons 3:1.
- Every interactive element is reachable by keyboard and shows a visible focus ring.
- Touch targets at least 44 by 44 points.
- Icon-only buttons have an accessible name. Do not convey state by colour alone.

## Responsive and native

- Check the narrowest supported width, a common phone, a tablet when supported, and a
  desktop width. Long words, translated strings, and empty data are part of the check.
- On native, check the smallest and largest supported phones, the safe areas (notch,
  home indicator), the keyboard open, and dynamic type at a larger size.
- Scroll belongs to one container. A full-screen app that scrolls as a whole page,
  or bounces past its edges, usually has a root without a fixed height.

## Common giveaways

These read as generated. Remove them unless the direction asks for one on purpose:

- a centred hero with two buttons side by side and a gradient behind it;
- three identical feature cards in a row;
- gradient text, glass cards over a blurred blob, glowing borders;
- emoji as icons in product UI;
- placeholder copy that imitates real content ("Lorem", fake testimonials, fake logos).
  Use clearly marked placeholders instead.
