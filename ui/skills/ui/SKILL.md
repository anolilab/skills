---
name: ui
description: >
  Builds and fixes user interfaces: web pages and components, and React Native or Expo
  screens. Fixes what a screenshot or a complaint shows (spacing, alignment, overflow,
  layering, responsive breakage, hover and focus states) and builds new surfaces in the
  product's existing style, then checks the result in a real browser or simulator. Use
  when the user says the UI looks wrong, sends a screenshot of a visual problem, or asks
  to build or restyle a page, component, dialog, or screen, or to review one. Not for backend logic, data
  pipelines, or documents meant for print.
---

# UI

The bar: someone glancing at the result should not be able to tell an agent made it,
and nothing next to the change should have moved.

## Pick the path

| The ask | Path |
| --- | --- |
| A bounded defect on an existing screen ("too much space on the right", "the banner sits above the composer") | [Fix](#fix) |
| A screenshot of the problem | [Fix](#fix), with the screenshot as the brief |
| A new panel, dialog, sheet, toast, or screen inside an existing app | [Add](#add) |
| A new page or visual system, with no product style to follow | [Build](#build) |
| "What's wrong with this screen?", a review or audit with no change asked for | [Review](#review) |

Whatever the path, the change is not done until it has been seen rendered. See
[Check it rendered](#check-it-rendered).

## Fix

1. **Name the defect** in one sentence, in the user's terms. "Looks off" is not a
   diagnosis; "the dialog's body is 48px wider than its header" is.
2. **Set the bounds** before touching code:
   - *change*: the element, viewport, and state that may change;
   - *keep*: everything outside the named defect that must not change: neighbours,
     content, and behaviour, including what breaks
     unseen: route slugs and anchor ids, form field names and order (autofill depends
     on them), analytics event names, `data-testid` and other selectors tests use, nav
     labels, legal or consent copy, and existing focus order, alt text, and contrast;
   - *proof*: the render that will show the fix, and the measurement it will report.
     On the web, also record the page's inventory of links, fields, and test hooks
     before editing, to compare after
     ([references/verify.md](references/verify.md#layout-and-structure-checks)).
3. **Find the code that draws it.** Start from the route or screen, and follow it
   through the components and variants to the token or style that produces the value.
   Do not guess where styles live, and do not start with a repo-wide search for things
   that look similar.
4. **Make the smallest change** that fixes the defect, in this order: delete what
   causes it, reuse a value or variant the product already has, correct an existing
   value, and only then add something new. When a change does not take effect, look for
   two rules cancelling each other before adding a third. Fix the parent rather than
   patching around it with negative margins or absolute positioning.
5. **Check every place the same code runs.** A fix to a shared component or token
   reaches all its uses; check them, not only the reported one.

If the same spacing or size has been tuned three times and still looks wrong, the
problem is structural: replace the separate values with one shared token. If you are
adjusting a value by eye and the second try missed, stop and render two or three
labelled candidates side by side, and let the user pick.

If the fix needs three or more components, widen the bounds from step 2 to cover them,
state the new bounds to the user, and continue in this path. Only when the product has
no style that could govern the fix does it become [Build](#build).

## Add

The existing app is the design. Before writing anything:

- check the installed component library first: the skeleton, empty state, alert, or
  form field you need probably exists;
- find the nearest sibling (another dialog, sheet, toast, or list row) and write down
  its radius, how it separates from the surface, density, type roles, motion, and
  wording, plus what the product never uses (shadows, button icons, gradients). Reuse
  all of it. When siblings disagree, follow the majority, not the outlier;
- copy its states: loading, empty, error, disabled, focused;
- give a destructive action an undo, or a confirmation when it cannot be undone;
- add every new string to each locale catalog the app has;
- a new visual style needs a stated reason why no existing component fits.

## Build

Only when there is no product style to follow. Settle these first, from the repo, its
history, and other products by the same team, before asking the user anything:

1. who uses it and in what situation (a dense dashboard is not a landing page);
2. the direction, named precisely ("ink on paper, dense, high contrast", not "clean and
   modern"). A reference product the user names gives three concrete properties to copy:
   corner radius, how surfaces separate (shadow, background step, or border), and the
   accent colour family;
3. one signature element: a typeface, a colour system, a layout, or a motion;
4. hard constraints: framework, bundle size, contrast, keyboard access.

Ask at most one round of questions, with your best guess stated for each, and only
where the answer would change the result. Then state the direction in one line before
the first component. For taste calls (an icon, an accent, a weight, a motion feel), offer
two or three labelled options rather than one guess.

The craft rules, bans, and type and colour defaults are in
[references/craft.md](references/craft.md). Read it for Add and Build, and for any Fix
that touches type, colour, motion, forms, or overflow.

## Review

Read-only. Report problems, change nothing until the user picks.

- Keep a finding only with all three: a rule it breaks (a documented decision, a token,
  a sibling that does it right, or a direct contradiction on the same screen), proof
  that the code you cite actually renders on that screen, and one correction the
  evidence settles. "Could be cleaner" is not a finding.
- Hierarchy, density, and clarity need the rendered screen, not source alone. Name the
  screen's focal element, then blur the screenshot: the eye should still land there.
- Try to refute each finding before reporting it, and merge findings with one cause.
- Report at most three, ranked by evidence and reach, then ask which to fix.

## Rules for every path

- No gradient text, default glass cards, thick coloured side borders, the reflex
  purple-to-blue palette, rows of identical rounded shadow cards, or modals used to
  escape ordinary overflow.
- No `transition: all`, and no animating `width`, `height`, `top`, or `left`; animate
  `transform` and `opacity`. Do not add animation the user did not ask for.
- Use the product's accessible primitives (Radix, Base UI, React Aria, or the design
  system) for anything with focus or keyboard behaviour. Never rebuild that behaviour by
  hand, and never mix two primitive systems in one surface.
- Full-height layouts use `100dvh` (`h-dvh`), not `100vh` (`h-screen`), which is taller
  than the visible area on mobile browsers and makes the page scroll.
- Show an error next to the control that caused it. Never block paste into an input.
- Anything triggered from the keyboard, or used hundreds of times a day, gets no
  animation. Every action shows an immediate result: a pressed state on pointer-down,
  then a selected, open, or loading state. Never show a change by motion alone.
- While data is still on its way, show progress. The "nothing here" state is for a
  request that finished and returned nothing.
- A submit cannot fire twice, a failed request keeps what the user typed, and an
  optimistic update rolls back when it fails. Cancel in-flight reads when the component
  unmounts; do not abort a submit or other write unless its API supports cancellation,
  since the server may already have applied it.
- A slot that swaps content by state keeps one font size across states, so it does not
  jump.
- Text fits by design: shorten the format or cap the content, never rely on an ellipsis
  for numbers or labels, and never shrink type to save one orphan word. Anything that
  is truncated still has a way to its full value.
- Nothing shifts once rendered: reserve space for images and async content, and keep
  border width, weight, and padding the same across hover, selected, and error states.
- React Native and Expo screens follow the platform rules in
  [references/craft.md](references/craft.md#react-native-and-expo): safe areas, the
  keyboard, layering, one scroll container, and both platforms checked.
- For an existing native app, polish its own style. Do not propose moving it to a newer
  platform look unless the user asked.

## Check it rendered

When the user asks for a UI change, checking it in a browser or simulator is part of
that request. Say so in one line ("I'll check it in the browser"), then do it. How
depends on the harness and the platform:
[references/verify.md](references/verify.md).

The check covers the bounds from step 2: the changed state, at 320px, a phone, and a
desktop width, in light and dark when the app has both, plus the siblings from step 5.
On the web, run the layout probe at each width and compare the inventory with the one
taken before. A change to something interactive also gets a keyboard pass. A change to motion is
watched slowed down, because a still frame cannot show it. A gesture is performed, not
screenshotted. A spacing or
alignment fix reports numbers: the element's measured box before and after, and the
viewport width. Finish with one line:

```
checked <N> places, changed <M>, left <K> as they were; untested: <what and why>
```

If nothing can render here, say so and name the exact screen and state the user should
look at.

## Hand off

- what changed and why, in two or three sentences;
- the evidence: screenshots or measurements, and the `checked / changed / left` line;
- for a new surface: the direction in one line, and what is placeholder content.
