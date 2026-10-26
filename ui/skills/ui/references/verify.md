# Checking a UI change rendered

## Contents

- Web: browser-use
- Interaction, accessibility, and motion
- In T3 Code: iOS and Android
- Outside T3 Code
- Measuring

Pick the first route that works. Close what you opened when you are done.

Start dev servers and Expo in the background, and block until their log shows the ready
line (the local URL, or the bundle finishing), with the harness's background-wait or
monitor tool. A single read can come before the line appears; if it is not there, wait
again rather than continuing. Never a `sleep` loop.

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
new_tab(URL)  # the URL from the dev-server log plus the route under test
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

3. Read the screenshots. Reach the state under test before capturing: `click_at_xy` for
   clicks, opening, and focus; for hover, move the pointer without clicking,
   `cdp("Input.dispatchMouseEvent", type="mouseMoved", x=x, y=y)`. Find the element's
   coordinates through the accessibility tree, as the `browser-use` skill describes.
4. Clear the overrides, close the tab you opened, and stop the dev server.

Screenshots are in device pixels; coordinates for clicks are CSS pixels.

Add `("narrow", 320, 640, True)` to the sizes for any layout change. A 1280px window at
200% browser zoom is a 640px CSS viewport: check that width too when text or layout
moved.

## Interaction, accessibility, and motion

Screenshots prove layout, nothing else. For the rest, in the same browser-use tab:

- **Keyboard:** press Tab through the changed flow
  (`cdp("Input.dispatchKeyEvent", type="keyDown", key="Tab")` and `keyUp`), and after
  each step read `js("document.activeElement.outerHTML.slice(0, 200)")` and take a
  screenshot. Focus must be visible and never hidden under a sticky bar.
- **Names and roles:** read `cdp("Accessibility.getFullAXTree")["nodes"]`, filtered to
  the changed area, for missing names on buttons, a dialog without a title, and heading
  order.
- **Touch:** `cdp("Emulation.setTouchEmulationEnabled", enabled=True, maxTouchPoints=5)`
  with the phone size, then tap, to confirm hover styles do not stick. Disable it after,
  without `maxTouchPoints`.
- **Motion:** slow every animation down with
  `cdp("Animation.setPlaybackRate", playbackRate=0.2)` and take screenshots during the
  transition. Look for two states overlapping, a wrong origin, or properties out of
  step. Set the rate back to 1.
- **Gestures:** perform the drag or swipe with pointer events, then swipe across the
  control along the page's scroll axis and confirm the page scrolls and the control
  does not. Cancel one drag midway (`pointercancel`) and confirm the next drag works.
- **Hierarchy:** take one screenshot with `js("document.body.style.filter = 'blur(6px)'")`
  and one with `grayscale(1)`, then clear the filter. The focal element and the groups
  must still read in order without detail or colour.
- **Colour meaning:** when colour carries status or chart series, screenshot under
  `cdp("Emulation.setEmulatedVisionDeficiency", type="deuteranopia")` and `"achromatopsia"`,
  then reset with `type="none"`. Every state must still be told apart.
- **Hostile content:** for lists, tables, and anything showing user text, put in a
  100-character name, emoji, CJK text, and many rows (through the app's fixtures or a
  temporary `js` edit of the rendered text), and confirm nothing overflows. Check the
  longest locale the app ships.
- **What a screenshot cannot show:** confirm the intended font loaded
  (`js("document.fonts.check('16px \"Inter\"')")` with the product's font, and the
  element's computed `fontFamily`), compute the
  contrast of changed text from its rendered colours in both themes, and search the diff
  for hex or `rgb()` literals, raw `z-index` numbers, and pixel values that are not in
  the token file.

A simulator does not show real touch feel or device performance. Name that in the
`untested` part of the final line when it matters.

## In T3 Code: iOS and Android

For React Native and Expo apps, T3 Code drives simulators and emulators:

1. `device_list` to find a device, then `device_open` with its id or `platform`. It
   boots the device and returns the `agent-device` CLI command pinned to it; use that
   CLI for taps, typing, and navigation.
2. Start the app on it in the background: `npx expo start --ios` (or `--android`) for
   Expo Go, or `npx expo run:ios` when the project has native code, and wait on its log
   for the bundle to finish.
3. Navigate to the screen with the `agent-device` CLI and take a `device_screenshot`.
   Check the smallest supported phone and a large one, dark mode when supported, a
   larger text size, and the keyboard open for any screen with an input (in the iOS
   Simulator, turn off I/O > Keyboard > Connect Hardware Keyboard, or the software
   keyboard never appears).
4. `device_close` when done.

Make one bounded attempt to drive the device to the screen. If taps, focus, or
navigation turn flaky, stop and ask the user for a screenshot of the exact screen and
state, rather than spending rounds on automation.

## Outside T3 Code

- **iOS Simulator:** pick a device from `xcrun simctl list devices available`, then
  `xcrun simctl boot <udid>` (already booted is fine) and
  `xcrun simctl bootstatus <udid> -b` to wait until it is ready. Start the app with
  `npx expo start --ios`, then `xcrun simctl io <udid> screenshot /tmp/ui-check.png`
  and read the image. For dark mode and large text, first note the current values
  (`xcrun simctl ui <udid> appearance` and `xcrun simctl ui <udid> content_size` print
  them), then set `appearance dark` and `content_size extra-extra-large`, take and
  read a screenshot for each, and set the noted values back.
- **Android Emulator:** pick the serial from `adb devices` (start one with
  `emulator -avd <name>` if none is listed), then `adb -s <serial> wait-for-device`.
  Start the app with `npx expo start --android`, then
  `adb -s <serial> exec-out screencap -p > /tmp/ui-check.png`. For dark mode and large
  text, first note the current values (`adb -s <serial> shell cmd uimode night` and
  `adb -s <serial> shell settings get system font_scale`), then set
  `shell cmd uimode night yes` and `shell settings put system font_scale 1.3`, take and
  read a screenshot for each, and write the noted values back.
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
