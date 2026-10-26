# UI craft rules

## Contents

- Read the product first
- Component libraries and Tailwind
- Hierarchy
- Typography
- Colour
- Spacing and layout
- Surfaces
- Motion
- Gestures
- Interface copy
- Feedback and loading
- Forms
- Data display
- Accessibility
- Responsive and native
- React Native and Expo
- Common giveaways

## Read the product first

A `DESIGN.md` or design documentation that is current and covers this surface governs
it; read it first. A draft or a migration plan describes intent, not the rules.

Take values from the code, not from memory: the theme or token file (`theme.ts`,
`tokens.css`, `tailwind.config.*`, a design-system package), the global stylesheet, and
the sibling components. Lift exact values: colours, the spacing scale, font stacks,
radii. Note what the product never does (no shadows, no icons in buttons, no
gradients): an absence is a decision too, so do not add it. When the token file and the
components disagree, or siblings disagree with each other, follow what most shipped
components use, and fold near-duplicate values (`#333` next to `#2c2c2c`) onto the
token. Name the one styling approach the repo uses (Tailwind, CSS modules, styled
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

## Hierarchy

- Each screen has one focal element: name it before building or reviewing, and demote
  everything else.
- Raise an element with one lever (size, weight, or contrast), not all three. Often the
  better move is to lower the rest: labels, table headers, and metadata get a quieter
  colour or weight.
- Text uses a small set of tiers (primary, secondary, tertiary, muted), not a new grey
  per component.
- One primary button per view; the others are secondary or plain text. A routine
  destructive action is a quiet button, not the loudest red on the screen; the red is
  for the confirming step.
- Space shows grouping: the gap between groups is larger than the gap inside them, and
  a heading has more space above it than below. When borders and cards are doing the
  grouping, the spacing is usually wrong.

## Typography

- One type scale, from the product. In a new system, five to seven sizes on one ratio.
- One text style per role inside a card or row, with hierarchy from order and weight.
  More than three styles in a small block is noise.
- Body text 15 to 17px on screens, line length 45 to 75 characters.
- Line height is unitless and follows the role: about 1.1 for display text, 1.2 to 1.3
  for headings, 1.4 to 1.6 for body. Anything that can wrap to three lines gets at least
  1.4, even inside a tight row. Wider columns and light text on dark need the upper end.
- Large headings get slightly negative tracking (about -0.02em). Small text keeps
  normal tracking, except all-caps labels, which need about +0.05em.
- Text under 18px uses weight 400 or heavier; light weights turn to hairlines.
- Load every weight and style the design uses, or the browser fakes them. Set weight
  with `font-weight` and figures with `font-variant-numeric`, not the low-level
  `font-variation-settings` or `font-feature-settings`, which fail silently on the
  fallback font.
- Form inputs on mobile web are at least 16px, or iOS Safari zooms in on focus.
- Size text and spacing in `rem` on the web, so the layout follows the user's text size.
- Headings wrap evenly with `text-wrap: balance`; paragraphs avoid orphans with
  `text-wrap: pretty`.
- Numbers that line up in tables and counters use tabular figures
  (`font-variant-numeric: tabular-nums`).
- User content, URLs, and IDs get `overflow-wrap: anywhere` (never `word-break:
  break-all`). Badges and short labels get `white-space: nowrap`. A number and its unit
  are joined by a non-breaking space.
- Use real typography in copy: `…`, en dashes for ranges, and curly quotes. Loading
  labels end in an ellipsis ("Saving…"). Brand names, code, and identifiers get
  `translate="no"` so browser translation leaves them alone.
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
  white text on large areas. A higher layer is a lighter surface, since shadows barely
  show on dark; where an edge is needed, use a 1px translucent ring. Accents and status
  colours go slightly lighter and less saturated. Keep one hue across surfaces and vary
  lightness. Light text on dark needs more contrast headroom than the 4.5:1 ratio
  suggests.
- Hover, pressed, and focus states raise contrast over the resting state, never lower
  it.
- Browser-drawn parts follow the theme: `<meta name="theme-color">` matches the page
  background, a native `<select>` gets an explicit background and text colour (Windows
  dark mode ignores the theme otherwise), and set `color-scheme` (or dark mode ships light
  scrollbars and form controls), `accent-color`, `caret-color`, and `::selection`.
- In OKLCH, a chroma outside the screen's gamut gets clipped; reduce chroma, never
  lightness or hue, to bring it back. Mix and interpolate gradients `in oklab` or
  `in oklch` to avoid a grey midpoint, and derive states with `color-mix()` or relative
  colour syntax rather than a second hard-coded hex.

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
- A dropdown or tooltip positioned absolutely inside an `overflow: hidden` or
  `overflow: auto` ancestor gets cut off. Render it in a portal (the component
  library's, when it has one). Use the popover API or `position: fixed` only where the
  app has no portal.
- When a spacing change does not take effect, look for two rules fighting before adding
  a third value: a class and an element selector, or a parent's padding and a child's
  margin, often cancel out.
- Fix the parent instead of working around it: no negative margins to undo its
  padding, no `calc()` escape hatches, and no absolute positioning to step out of the
  flow.
- Nothing moves once rendered. Images and async slots reserve their space (`width` and
  `height`, or `aspect-ratio`), and web fonts load without shifting the layout. Hover,
  selected, focus, and error states never change border width, font weight, padding, or
  size: use an outline, an inset shadow, or a border that was already there in a
  transparent colour.

## Surfaces

- Separate surfaces one way, consistently: a background step, a border, or a shadow.
  Mixing all three on one card is the default look to avoid.
- Corner radius follows nesting: an inner element's radius is the outer radius minus the
  padding between them. One radius and one soft shadow on everything reads as generated.
- A popover sits one step above the surface it opens from; inputs sit slightly below
  their surroundings; a sidebar shares the page background and is separated by a border.
- Borders use a low-opacity black or white, so they hold on any surface. Images and
  avatars get a 1px inset outline in black or white at about 10% so their edge does not
  bleed into the background.
- A shadow that stays in dark mode is tight and tinted toward the background, never a
  wide pure-black drop.
- Icons: one set, one stroke width, one filled-or-outline style per level, and a few
  size tokens. When an icon is smaller than its touch target, grow the hit area, not the
  glyph.

## Motion

- Animate `transform` and `opacity` only. Duration follows size and distance: small
  state changes 120 to 200ms, menus and popovers 150 to 250ms, full-height sheets and
  modals up to about 400ms. Keep everything else under 300ms.
- Use the product's motion tokens. In a new system, define three durations and one
  strong ease-out curve (for example `cubic-bezier(0.23, 1, 0.32, 1)`; the built-in
  `ease-out` is weak) and reuse them, so one kind of interaction always moves the same
  way.
- Ease out both ways, and leave faster than you enter. Ease-in on an exit feels slow at
  the moment the user is watching. Linear is only for constant motion: progress bars,
  spinners, steady rotation.
- Stagger list entrances by 30 to 80ms per item, with the whole cascade under about
  400ms. Exits do not stagger.
- A focus ring appears at once, never through a transition on `outline` or
  `box-shadow`. A tooltip opens after a hover delay (about 500 to 800ms) but immediately
  on keyboard focus.
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
- offer a single-pointer alternative (buttons, an input) for anything that only drags;
- end the drag cleanly on `pointercancel`, `lostpointercapture`, release outside the
  control, and window `blur`: clear the dragging state and release the pointer, so the
  next drag works without a reload.

## Interface copy

- A button names its outcome ("Save changes", "Delete project"), not "Submit" or "OK".
- One action keeps one name through the flow: "Publish", then "Publishing", then
  "Published".
- An error says what failed and how to fix it, without apology.
- An empty state says what will appear there and offers the next action.
- Copy the wording of the sibling component before inventing new phrasing.

## Feedback and loading

- Match the safeguard to the cost of a mistake. A reversible action (removing one row)
  happens at once with an Undo in a toast for 5 to 10 seconds. A confirmation dialog is
  for actions that cannot be undone.
- Success the user can already see needs no toast. Toasts are for failures and for
  effects off-screen. A toast never moves the content, never takes focus, and is
  announced politely.
- Show a spinner only after about 150ms, then keep it up for at least about 300ms, so a
  fast response does not flash. When the final layout is known, use a skeleton shaped
  like it.
- A failure in one region shows in that region and leaves the rest of the screen
  working.

## Forms

- A placeholder is an example, never the label. Labels stay visible while typing.
- An input is about as wide as what goes in it: a postcode field is not full width.
- Set the right `type`, `inputmode`, and `autocomplete` (on native, `keyboardType`,
  `textContentType`, `autoComplete`), so phones show the right keyboard and password
  managers and autofill work.
- Validate on blur or submit, not on every keystroke. State format rules before the user
  submits, and mark required or optional fields one consistent way.
- While a submit is in flight, disable the button so it cannot fire twice. After an
  error, keep everything the user typed. With several errors, move focus to the first
  invalid field or to an error summary. Roll back an optimistic update that failed.
- Ask before closing a sheet or dialog, or leaving the page, with unsaved input. Read-only
  looks different from disabled.
- Clicking a label focuses or toggles its control (`htmlFor`, or the control inside the
  label), and a checkbox or radio shares one hit area with its label. Turn spellcheck
  off for emails, codes, and usernames.

## Data display

- Right-align numbers, with one precision per column. Use light horizontal rules, not a
  grid of borders.
- Bar charts start at zero and label bars directly instead of through a legend where
  possible. Keep to five to seven categories.
- Chart series differ in lightness, not only in hue, and a chart fill has 3:1 contrast
  against its border or background.

## Accessibility

- Text contrast at least 4.5:1, large text and icons 3:1.
- Never disable zoom (`user-scalable=no`, `maximum-scale=1`).
- Every interactive element is reachable by keyboard and shows a visible focus ring,
  styled with `:focus-visible` (not `:focus`, which also rings on click) and
  `:focus-within` for compound controls. A
  sticky header, footer, composer, or banner never fully covers the focused element:
  give scroll targets a `scroll-margin` that clears it.
- Touch targets at least 44 by 44 points on iOS and 48 by 48dp on Android, with about
  8px between neighbouring targets. Dense desktop controls may go down to 24px.
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
- A destructive action has a confirmation or an undo; see Feedback and loading for
  which.
- After a route change, focus moves to the new main content.

## Responsive and native

- Check 320px wide and 200% browser zoom with nothing clipped or unreachable, a common
  phone, a tablet when supported, a desktop width, and landscape. Content that pushes
  back is part of the check: 100-character names, emoji, CJK text, a thousand rows, and
  an empty list.
- Most "too wide on one side" bugs come from the track, not the element: grid columns
  use `minmax(0, 1fr)` instead of a bare `1fr`, flex and grid children that hold text
  get `min-width: 0`, the page root uses `overflow-x: clip` rather than `hidden`, and
  nothing is sized in `100vw`. A button or nav label never wraps to two lines: shorten
  it, then `nowrap` it. Chips wrap to a new row before their labels shrink.
- Translations: a new label goes into every locale catalog the app has, not only the
  source language. Leave 30 to 40% extra width for longer languages (German is the
  usual test). Plurals, dates, and numbers go through `Intl` or the app's i18n library,
  never `count === 1 ? ... : ...`. Use logical properties (`margin-inline-start`, `ms-*`,
  `ps-*`) so right-to-left layouts work.
- State a user would share or return to (filters, tabs, pagination, an open panel)
  lives in the URL. Back restores the previous scroll position and filters. Never reset
  the navigation stack silently. Navigation is a link, so Cmd-click and middle-click
  work.
- Branch layout on available width or size class, not on device model. Going from phone
  to tablet usually restructures navigation (a rail or sidebar), and a tablet split into
  a phone-sized window must still work. Do not lock orientation to avoid a layout bug.
- Mobile web: set `viewport-fit=cover` and pad with `env(safe-area-inset-*)` (with a
  `max()` fallback), or fixed footers sit under the home indicator.
- On native, check the smallest and largest supported phones, the safe areas, the
  keyboard open, and dynamic type at a larger size.
- Native apps follow their platform: never disable the iOS edge swipe back or override
  Android's system back. Use the platform's text styles (`sp` on Android) and the
  design system's colour roles. Android draws edge to edge, so pad for the system bars
  and the keyboard through window insets.
- Scroll belongs to one container. A full-screen app that scrolls as a whole page,
  or bounces past its edges, usually has a root without a fixed height. Modals, sheets,
  and drawers get `overscroll-behavior: contain`, so scrolling them never moves the page
  behind. Lists of more than about 50 rows are virtualised (or use
  `content-visibility: auto`).
- Tappable elements get `touch-action: manipulation` to remove the double-tap zoom
  delay, and a deliberate `-webkit-tap-highlight-color`. While dragging, turn off text
  selection.
- Truncated or clipped content needs a way to the full value: a tooltip that keyboard
  and touch can reach, a detail view, or wrapping.

## React Native and Expo

Use what the repo already has (its navigation, keyboard, list, and animation libraries)
before adding one. A fix on one platform often breaks the other: check iOS and Android.

- **Safe areas:** `react-native-safe-area-context`, with one `SafeAreaProvider` at the
  root and `useSafeAreaInsets` or its `SafeAreaView` per screen, choosing the edges.
  Not React Native's own `SafeAreaView`, which only works on iOS. A navigator header
  already pads the top; padding again doubles the gap.
- **Keyboard:** a composer or form stays visible with the keyboard open. On iOS wrap the
  screen in `KeyboardAvoidingView` with `behavior="padding"`; on Android rely on
  `adjustResize` (`softwareKeyboardLayoutMode: "resize"` in the Expo config), or the
  keyboard library the repo uses on both. Scroll views holding inputs set
  `keyboardShouldPersistTaps="handled"` so the first tap on a button is not swallowed.
- **Layering:** `zIndex` only orders siblings, and on Android `elevation` also changes
  stacking. A banner that must sit behind a composer goes in the same parent, in the
  right order, not on a higher `zIndex` in another branch of the tree.
- **Scroll:** one scroll container per screen, and the screen root gets `flex: 1` so it
  does not grow with its content. Never put a `FlatList` inside a `ScrollView` of the
  same direction: virtualisation stops and every row renders. Long or growing lists use
  `FlatList` (or the repo's `FlashList`) with a stable `keyExtractor`. An empty state
  that should fill the screen uses `contentContainerStyle={{ flexGrow: 1 }}`.
- **Press:** `Pressable` with a pressed style, and `android_ripple` where the platform
  look calls for it. Small icons get `hitSlop` to reach the touch target size.
- **Shadows:** iOS uses the `shadow*` props and Android uses `elevation`; set both, or
  use `boxShadow` when the app is on the new architecture and the repo already does.
  Compare the two platforms side by side.
- **Animation:** gestures and anything that must stay smooth while JavaScript is busy
  run on the UI thread through Reanimated and `react-native-gesture-handler`. Which
  properties the built-in `Animated` native driver can animate depends on the app's
  React Native version (older versions exclude layout properties), so check the version
  before relying on it.
- **Text:** leave `allowFontScaling` on and design for large text. On Android,
  `includeFontPadding: false` fixes text that looks off-centre in a button.
- **Theme:** the status bar text contrasts with the screen behind it.
  `expo-status-bar` with `style="auto"` follows the system colour scheme, not the
  screen, so a screen whose background differs from the app's scheme (a dark media
  screen in light mode) sets `style="light"` or `"dark"` explicitly. Colours come from
  the theme hook the app uses, never hard-coded per screen.

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
