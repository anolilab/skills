# UI craft rules

## Contents

- Read the product first
- Component libraries and Tailwind
- Typography
- Colour
- Spacing and layout
- Surfaces
- Motion
- Gestures
- Interface copy
- Accessibility
- Responsive and native
- Common giveaways

## Read the product first

A `DESIGN.md` or design documentation that is current and covers this surface governs
it; read it first. A draft or a migration plan describes intent, not the rules.

Take values from the code, not from memory: the theme or token file (`theme.ts`,
`tokens.css`, `tailwind.config.*`, a design-system package), the global stylesheet, and
the sibling components. Lift exact values: colours, the spacing scale, font stacks,
radii. Name the one styling approach the repo uses (Tailwind, CSS modules, styled
components, `StyleSheet`) and write in it; never mix in a second.

## Component libraries and Tailwind

When the repo has a component library (a `components.json` for shadcn/ui, a design
system package), the library is the vocabulary:

- Read its setup first. For shadcn/ui, `npx shadcn@latest info` reports the primitive
  base (Radix or Base UI), the Tailwind version, the icon set, the aliases, and whether
  components are server components; `npx shadcn@latest docs <component>` gives the real
  API. Do not write a prop the base does not have, or import a second icon set.
- Look in the installed components before writing markup: a skeleton, empty state,
  alert, separator, spinner, or form field probably exists already.
- Restyle in this order: a built-in variant, then a semantic token, then a CSS variable
  in the global stylesheet the repo already has. A `className` on a library component is
  for layout only. A colour class on one Card changes one Card and breaks it in dark
  mode.
- Use semantic tokens (`bg-background`, `text-muted-foreground`), never a pair like
  `bg-white dark:bg-gray-950`. A raw status colour becomes a variant or a token.
- After adding a component from a registry, read the new files, fix import aliases, and
  preview updates with `--dry-run` or `--diff` so local edits are not overwritten.

## Typography

- One type scale, from the product. In a new system, five to seven sizes on one ratio.
- One text style per role inside a card or row, with hierarchy from order and weight.
  More than three styles in a small block is noise.
- Body text 15 to 17px on screens, line length 45 to 75 characters, line height 1.4 to
  1.6. Large headings get tighter line height and slightly negative tracking (about
  -0.02em); small text gets neither.
- Form inputs on mobile web are at least 16px, or iOS Safari zooms in on focus.
- Size text and spacing in `rem` on the web, so the layout follows the user's text size.
- Headings wrap evenly with `text-wrap: balance`; paragraphs avoid orphans with
  `text-wrap: pretty`.
- Numbers that line up in tables and counters use tabular figures
  (`font-variant-numeric: tabular-nums`).
- The system font is a sound default for product UI: it ships optical sizes and tuned
  spacing. Replace it only for a stated reason. Marketing surfaces may choose otherwise.

## Colour

- Use the product's tokens. A new colour needs a token, not a hex literal in a component.
- In a new system, define colours in OKLCH so lightness steps are even, and derive
  hover, pressed, and disabled states from one base by lightness.
- One accent colour, used for the primary action and focus, not for decoration.
- Semantic colours keep their meaning: the danger colour only on destructive actions,
  the success colour only on success. A neutral button in red reads as a delete.
- Dark mode is its own palette: lower contrast between surfaces, no pure black or pure
  white text on large areas.

## Spacing and layout

- One spacing scale (for example 4, 8, 12, 16, 24, 32). The outer padding of a container
  defaults to the gap between its children.
- Space children with `gap` on a flex or grid parent, not margins on the children
  (`space-x-*` in Tailwind): margins break when a child is hidden or the row wraps.
- Width comes from a shared container token, taken from a sibling page when one exists.
- Stacking order for page chrome uses named layers (base, sticky, overlay, toast), not
  ad hoc `z-index` numbers. A banner that must sit behind a composer is a layer
  decision. Overlays from a component library (dialog, sheet, popover) manage their own
  stacking through a portal: do not add a `z-index` to them.
- When a spacing change does not take effect, look for two rules fighting before adding
  a third value: a class and an element selector, or a parent's padding and a child's
  margin, often cancel out.

## Surfaces

- Separate surfaces one way, consistently: a background step, a border, or a shadow.
  Mixing all three on one card is the default look to avoid.
- Corner radius follows nesting: an inner element's radius is the outer radius minus the
  padding between them. One radius and one soft shadow on everything reads as generated.

## Motion

- Animate `transform` and `opacity` only. Small state changes take 120 to 200ms; menus
  and popovers 150 to 250ms; keep interface motion under 300ms.
- Ease out both ways, and leave faster than you enter. Ease-in on an exit feels slow at
  the moment the user is watching. No linear easing on UI elements.
- Pressable elements answer on pointer-down: a slight scale to about 0.97 within 100 to
  160ms, and the action runs on release.
- Nothing enters from `scale(0)`. Start near 0.95 with opacity 0. A popover or menu grows
  from its trigger (`transform-origin`); a modal grows from the centre. Leave the way you
  came in.
- Motion that can fire repeatedly (toasts, toggles, list changes) uses transitions, not
  keyframes, so a second trigger continues from where the first one is. Never block input
  while something animates, and clean up listeners when the component unmounts.
- No motion for keyboard-triggered actions or for anything used constantly.
- Reduced motion means gentler, not none: replace slides and springs with a short fade
  and keep colour and opacity cues. Never show a state change by motion alone; leave a
  colour, icon, or label. Honour `prefers-reduced-transparency` and
  `prefers-contrast: more` by making translucent surfaces solid with a visible border.
- Prefer CSS transitions or the Web Animations API for fixed animations; main-thread
  animation stutters while the page is busy. Work inside the animation library the
  repo already uses; do not migrate or mix libraries.
- Never read layout and write styles in the same frame. Measure once, then animate with
  `transform` (the measure-then-invert approach) for anything that looks like a layout
  change.
- Scroll-linked motion uses scroll or view timelines (`animation-timeline: view()`), not
  scroll event handlers. Pause looping animations off-screen with an
  `IntersectionObserver`, and give every `requestAnimationFrame` loop a stop condition.
- Blur stays small (8px or less), short, and off large surfaces; never animate
  `backdrop-filter` across a whole screen. Set `will-change` only while an animation
  runs.
- View transitions are for navigation between pages, not for interactions that can be
  interrupted. Use `@starting-style` for entry instead of
  a mount effect. Do not update a CSS variable on a parent every frame: it restyles every
  child.
- Fix stutter or jumps before changing speed.

## Gestures

For drag, swipe, sheets, and sliders:

- capture the pointer, so the drag continues outside the element;
- keep the grab offset instead of snapping the element's centre to the finger;
- ignore a second touch once a drag has started;
- decide the direction after about 10px of movement, and let the page scroll when the
  movement is along its axis;
- dismiss on a fast flick as well as past a distance;
- resist progressively at the edges instead of stopping hard;
- offer a single-pointer alternative (buttons, an input) for anything that only drags.

## Interface copy

- A button names its outcome ("Save changes", "Delete project"), not "Submit" or "OK".
- One action keeps one name through the flow: "Publish", then "Publishing", then
  "Published".
- An error says what failed and how to fix it, without apology.
- An empty state says what will appear there and offers the next action.
- Copy the wording of the sibling component before inventing new phrasing.

## Accessibility

- Text contrast at least 4.5:1, large text and icons 3:1.
- Every interactive element is reachable by keyboard and shows a visible focus ring. A
  sticky header, footer, composer, or banner never fully covers the focused element:
  give scroll targets a `scroll-margin` that clears it.
- Touch targets at least 44 by 44 points. Dense desktop controls may go down to 24px.
- Hover styles only where hover exists: wrap them in
  `@media (hover: hover) and (pointer: fine)`, so they do not stick after a tap. Hover is
  never the only way to reach a function.
- Prefer native elements (`button`, `a`, `input`) to roles on a `div`, and add ARIA only
  where native semantics do not cover it. No `tabindex` above 0.
- Icon-only buttons have an accessible name, and decorative icons are hidden from
  assistive tech. Do not convey state by colour alone, including disabled states.
- Dialogs, sheets, and drawers have a title (visually hidden if the design has none),
  move focus inside on open, keep it there, close on Escape, and return focus to the
  control that opened them.
- Form errors are tied to their field (`aria-describedby`, `aria-invalid`), and urgent
  ones are announced (`aria-live`). A disabled submit button says why. A toast is never
  the only place important information appears.
- Controls that expand or collapse expose `aria-expanded`.
- A destructive action has a confirmation, an undo, or clearly different treatment.

## Responsive and native

- Check 320px wide and 200% browser zoom with nothing clipped or unreachable, a common
  phone, a tablet when supported, a desktop width, and landscape. Long words, translated
  strings, and empty data are part of the check.
- Branch layout on available width or size class, not on device model. Going from phone
  to tablet usually restructures navigation (a rail or sidebar), and a tablet split into
  a phone-sized window must still work. Do not lock orientation to avoid a layout bug.
- Mobile web: set `viewport-fit=cover` and pad with `env(safe-area-inset-*)` (with a
  `max()` fallback), or fixed footers sit under the home indicator.
- On native, check the smallest and largest supported phones, the safe areas, the
  keyboard open, and dynamic type at a larger size.
- Scroll belongs to one container. A full-screen app that scrolls as a whole page,
  or bounces past its edges, usually has a root without a fixed height.
- Truncated or clipped content needs a way to the full value: a tooltip that keyboard
  and touch can reach, a detail view, or wrapping.

## Common giveaways

These read as generated. Remove them unless the direction asks for one on purpose:

- a centred hero with two buttons side by side and a gradient behind it;
- three identical feature cards in a row;
- gradient text, glass cards over a blurred blob, glowing borders;
- tracked all-caps labels above every heading, `01 / 02 / 03` numbering on things that
  are not steps, an arrow after every link, meta lines joined by middle dots;
- emoji as icons in product UI;
- placeholder copy that imitates real content ("Lorem", fake testimonials, fake logos).
  Use clearly marked placeholders instead.
