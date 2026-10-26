# Checking a UI change rendered

## Contents

- Web: browser-use
- In T3 Code: iOS and Android
- Outside T3 Code
- Measuring

Pick the first route that works. Close what you opened when you are done.

Start dev servers and Expo in the background, and wait on their log for the ready line
with the harness's background-wait or monitor tool, or read the log once. Never a
`sleep` loop.

## Web: browser-use

Use the `browser-use` CLI (install: `uv tool install browser-use`; its skill:
`npx skills add https://github.com/browser-use/browser-use --skill browser-use`). It
drives the user's running Chrome over CDP. The first run asks Chrome to allow remote
debugging; on macOS, leave that command running and call `browser-use mac-approve` in a
second call. `browser-use --doctor` diagnoses a daemon that will not connect.

1. Start the dev server with the repo's own script (`pnpm dev`, or what `package.json`
   names) and read the URL from its log.
2. Open one tab, then check each size and colour scheme from the bounds:

```bash
browser-use <<'PY'
new_tab("http://localhost:5173/settings")
wait_for_load()
for name, w, h, mobile in [("phone", 375, 812, True), ("desktop", 1440, 900, False)]:
    cdp("Emulation.setDeviceMetricsOverride", width=w, height=h, deviceScaleFactor=2, mobile=mobile)
    for scheme in ("light", "dark"):
        cdp("Emulation.setEmulatedMedia", features=[{"name": "prefers-color-scheme", "value": scheme}])
        capture_screenshot(f"/tmp/ui-{name}-{scheme}.png", max_dim=1800)
cdp("Emulation.clearDeviceMetricsOverride")
cdp("Emulation.setEmulatedMedia", features=[])
PY
```

3. Read the screenshots. Reach the state under test (open the dialog, hover, focus,
   load an empty list) with the accessibility tree and `click_at_xy`, as the
   `browser-use` skill describes, before capturing.
4. Clear the overrides, close the tab you opened, and stop the dev server.

Screenshots are in device pixels; coordinates for clicks are CSS pixels.

## In T3 Code: iOS and Android

For React Native and Expo apps, T3 Code drives simulators and emulators:

1. `device_list` to find a device, then `device_open` with its id or `platform`. It
   boots the device and returns the `agent-device` CLI command pinned to it; use that
   CLI for taps, typing, and navigation.
2. Start the app on it in the background: `npx expo start --ios` (or `--android`) for
   Expo Go, or `npx expo run:ios` when the project has native code, and wait on its log
   for the bundle to finish.
3. Navigate to the screen with the `agent-device` CLI and take a `device_screenshot`.
   Check the smallest supported phone and a large one, and dark mode when supported.
4. `device_close` when done.

Make one bounded attempt to drive the device to the screen. If taps, focus, or
navigation turn flaky, stop and ask the user for a screenshot of the exact screen and
state, rather than spending rounds on automation.

## Outside T3 Code

- **iOS Simulator:** `xcrun simctl list devices booted`, start the app with
  `npx expo start --ios`, then `xcrun simctl io booted screenshot /tmp/ui-check.png`
  and read the image.
- **Android Emulator:** `adb devices`, start the app with `npx expo start --android`,
  then `adb exec-out screencap -p > /tmp/ui-check.png`.
- **Web:** browser-use, as above, works in any harness. Without it, use the repo's
  Playwright or Cypress setup. Take screenshots at a phone and a desktop width.
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

With browser-use, run it inside `js(...)`. Report both sets and the viewport width.
On a device, compare the two screenshots at the same scale.
