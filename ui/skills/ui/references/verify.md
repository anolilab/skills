# Checking a UI change rendered

## Contents

- In T3 Code: web
- In T3 Code: iOS and Android
- Outside T3 Code
- Measuring

Pick the first route that works. Close what you opened when you are done.

## In T3 Code: web

T3 Code's preview tools are deferred: load them with ToolSearch (`preview_open`,
`preview_resize`, `preview_set_appearance`, `preview_snapshot`, `preview_evaluate`,
`t3_preview_close`) before calling them. Their own description allows them when the
request asks to check an edit in the browser, which a UI change request does, so tell
the user you will check it.

1. Start the dev server in the background with the repo's own script (`pnpm dev`, or
   what `package.json` names). Wait on its log for the ready line with
   `t3_background_wait`, never with `sleep`, and read the URL from it.
2. `preview_open` with that URL.
3. `preview_resize` to a phone preset (`iphone-se` or `pixel-7`), then to a desktop
   width (`freeform`, 1440 x 900). Add the width where the layout breaks if the fix is
   about a breakpoint.
4. `preview_set_appearance` to `dark` and `light` when the app supports both.
5. `preview_snapshot` with `includeImage: true` at each size and state. Use `save: true`
   for the screenshots you put in the handoff.
6. Close the tab with `t3_preview_close` and stop the dev server.

## In T3 Code: iOS and Android

For React Native and Expo apps, T3 Code drives simulators and emulators:

1. `device_list` to find a device, then `device_open` with its id or `platform`. It
   boots the device and returns the `agent-device` CLI command pinned to it; use that
   CLI for taps, typing, and navigation.
2. Start the app on it in the background: `npx expo start --ios` (or `--android`) for
   Expo Go, or `npx expo run:ios` when the project has native code. Wait on its log for
   the bundle to finish with `t3_background_wait`, never with `sleep`.
3. Navigate to the screen with the `agent-device` CLI and take a `device_screenshot`.
   Check the smallest supported phone and a large one, and dark mode when supported.
4. `device_close` when done.

Make one bounded attempt to drive the device to the screen. If taps, focus, or
navigation turn flaky, stop and ask the user for a screenshot of the exact screen and
state, rather than spending rounds on automation.

## Outside T3 Code

Start dev servers and Expo in the background and wait on their log with the harness's
monitor or background-wait tool, or read the log once; never a `sleep` loop.

- **iOS Simulator:** `xcrun simctl list devices booted`, start the app with
  `npx expo start --ios`, then `xcrun simctl io booted screenshot /tmp/ui-check.png`
  and read the image.
- **Android Emulator:** `adb devices`, start the app with `npx expo start --android`,
  then `adb exec-out screencap -p > /tmp/ui-check.png`.
- **Web:** use the repo's Playwright or Cypress setup if it has one, or the harness's
  browser tool. Take screenshots at a phone and a desktop width.
- **Nothing available:** say so, and give the user the exact screen, viewport, and
  state to look at.

## Measuring

Alignment and spacing fixes close with numbers. In a browser, read the boxes before and
after the change:

```js
[...document.querySelectorAll('<selector>')].map(el => {
  const r = el.getBoundingClientRect();
  return { el: el.className, x: r.x, y: r.y, w: r.width, h: r.height };
});
```

In T3 Code run it with `preview_evaluate`. Report both sets and the viewport width.
On a device, compare the two screenshots at the same scale.
