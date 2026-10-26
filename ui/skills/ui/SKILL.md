---
name: ui
description: >
  Builds and fixes user interfaces: web pages and components, and React Native or Expo
  screens. Fixes what a screenshot or a complaint shows (spacing, alignment, overflow,
  layering, responsive breakage, hover and focus states) and builds new surfaces in the
  product's existing style, then checks the result in a real browser or simulator. Use
  when the user says the UI looks wrong, sends a screenshot of a visual problem, or asks
  to build or restyle a page, component, dialog, or screen. Not for backend logic, data
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

Whatever the path, the change is not done until it has been seen rendered. See
[Check it rendered](#check-it-rendered).

## Fix

1. **Name the defect** in one sentence, in the user's terms. "Looks off" is not a
   diagnosis; "the dialog's body is 48px wider than its header" is.
2. **Set the bounds** before touching code:
   - *change*: the element, viewport, and state that may change;
   - *keep*: the neighbours, content, and behaviour that must not;
   - *proof*: the render that will show the fix, and the measurement it will report.
3. **Find the code that draws it.** Search for the component or class name and read the
   file. Do not guess where styles live.
4. **Make the smallest change** that fixes the defect: spacing, size, layering, opacity,
   type, or text fit, before any restructuring. Use the product's existing tokens.
5. **Check every place the same code runs.** A fix to a shared component or token
   reaches all its uses; check them, not only the reported one.

If the same spacing or size has been tuned three times and still looks wrong, the
problem is structural: replace the separate values with one shared token. If you are
adjusting a value by eye and the second try missed, stop and render two or three
labelled candidates side by side, and let the user pick.

If the fix needs three or more components, or reveals that the design direction is
wrong rather than one element, stop and treat it as [Build](#build).

## Add

The existing app is the design. Before writing anything:

- find the nearest sibling (another dialog, sheet, toast, or list row) and reuse its
  container, spacing, type, colour tokens, and motion;
- copy its states: loading, empty, error, disabled, focused;
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
that touches type, colour, or motion.

## Rules for every path

- No gradient text, default glass cards, thick coloured side borders, the reflex
  purple-to-blue palette, rows of identical rounded shadow cards, or modals used to
  escape ordinary overflow.
- No `transition: all`, and no animating `width`, `height`, `top`, or `left`; animate
  `transform` and `opacity`.
- Anything triggered from the keyboard, or used hundreds of times a day, gets no
  animation. Every action shows an immediate result: a selected, open, or loading state.
- While data is still on its way, show progress. The "nothing here" state is for a
  request that finished and returned nothing.
- A slot that swaps content by state keeps one font size across states, so it does not
  jump.
- Text fits by design: shorten the format or cap the content, never rely on an ellipsis
  for numbers or labels, and never shrink type to save one orphan word.
- For an existing native app, polish its own style. Do not propose moving it to a newer
  platform look unless the user asked.

## Check it rendered

When the user asks for a UI change, checking it in a browser or simulator is part of
that request. Say so in one line ("I'll check it in the preview"), then do it. How
depends on the harness and the platform:
[references/verify.md](references/verify.md).

The check covers the bounds from step 2: the changed state, at a narrow and a wide size,
in light and dark when the app has both, plus the siblings from step 5. A spacing or
alignment fix reports numbers: the element's measured box before and after, and the
viewport width. Finish with one line:

```
checked <N> places, changed <M>, left <K> as they were
```

If nothing can render here, say so and name the exact screen and state the user should
look at.

## Hand off

- what changed and why, in two or three sentences;
- the evidence: screenshots or measurements, and the `checked / changed / left` line;
- for a new surface: the direction in one line, and what is placeholder content.
