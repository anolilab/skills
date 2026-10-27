// Layout, focus, and structure checks for a rendered web page.
//
// Run it through browser-use by prepending the file to each call, so a navigation
// never leaves it missing:
//
//   probe = open("<skill-dir>/scripts/probe.js").read()
//   js(probe + "uiProbe.layout()")
//
// uiProbe.layout()     findings at the current viewport, scrolling the whole page
// uiProbe.rest()       remembers how every focusable element looks unfocused
// uiProbe.focus()      after a Tab: what has focus and whether it looks focused
// uiProbe.inventory()  links, fields, test ids, and handlers, to compare before
//                      and after a change
//
// Every call returns plain JSON. Findings name the element and say what is wrong;
// they are leads to confirm on a screenshot, not verdicts.
(() => {
  const MAX_FINDINGS = 40;
  const CONTROLS = 'button, [role="button"], [role="tab"], [role="menuitem"], nav a, input[type="submit"], input[type="button"]';
  const MEDIA = new Set(["IMG", "VIDEO", "CANVAS", "SVG", "IFRAME", "PICTURE"]);

  // Two frames so a new viewport has settled; a background tab never paints, so a
  // timer (throttled there to about a second) stands in for the frames.
  const frames = () => new Promise((done) => {
    const timer = setTimeout(done, 100);
    requestAnimationFrame(() => requestAnimationFrame(() => {
      clearTimeout(timer);
      done();
    }));
  });

  const name = (el) => {
    let out = el.tagName.toLowerCase();
    if (el.id) out += `#${el.id}`;
    else if (typeof el.className === "string" && el.className.trim()) out += `.${el.className.trim().split(/\s+/).slice(0, 2).join(".")}`;
    const text = (el.innerText || el.getAttribute("aria-label") || "").trim().replace(/\s+/g, " ");
    return text ? `${out} "${text.slice(0, 40)}"` : out;
  };

  const shown = (el) => {
    if (el.closest('[aria-hidden="true"], [inert], [hidden]')) return false;
    const style = getComputedStyle(el);
    const box = el.getBoundingClientRect();
    return box.width > 0 && box.height > 0 && style.visibility !== "hidden" && Number(style.opacity) > 0;
  };

  const ancestors = function* (el) {
    for (let node = el; node && node.nodeType === 1; node = node.parentElement) yield node;
  };

  const pinned = (el) => [...ancestors(el)].some((node) => ["fixed", "sticky"].includes(getComputedStyle(node).position));

  const scrollsSideways = (el) => [...ancestors(el.parentElement)].some((node) => {
    if (node === document.documentElement || node === document.body) return false;
    return ["auto", "scroll", "hidden", "clip"].includes(getComputedStyle(node).overflowX);
  });

  // Something only counts as covering text when it paints at that point.
  const paints = (el) => {
    if (MEDIA.has(el.tagName.toUpperCase())) return true;
    const style = getComputedStyle(el);
    if (style.backgroundImage !== "none") return true;
    const colour = style.backgroundColor.match(/[\d.]+/g);
    return Boolean(colour) && (colour.length < 4 || Number(colour[3]) > 0.05);
  };

  const textBoxes = (el) => {
    const boxes = [];
    for (const node of el.childNodes) {
      if (node.nodeType !== 3 || !node.textContent.trim()) continue;
      const range = document.createRange();
      range.selectNodeContents(node);
      boxes.push(...[...range.getClientRects()].filter((box) => box.width > 1 && box.height > 1));
    }
    return boxes;
  };

  const textElements = () => [...document.body.querySelectorAll("*")].filter((el) =>
    [...el.childNodes].some((node) => node.nodeType === 3 && node.textContent.trim()) && shown(el));

  // The part of a box left visible by every ancestor that clips its overflow.
  const visiblePart = (el, box) => {
    let { left, top, right, bottom } = box;
    for (const node of ancestors(el.parentElement)) {
      if (node === document.documentElement || node === document.body) break;
      const style = getComputedStyle(node);
      if (style.overflowX === "visible" && style.overflowY === "visible") continue;
      const clip = node.getBoundingClientRect();
      left = Math.max(left, clip.left);
      top = Math.max(top, clip.top);
      right = Math.min(right, clip.right);
      bottom = Math.min(bottom, clip.bottom);
    }
    return right - left > 1 && bottom - top > 1 ? { left, top, right, bottom } : null;
  };

  function checkScreen(texts, findings) {
    const width = document.documentElement.clientWidth;
    for (const el of texts) {
      const outer = el.getBoundingClientRect();
      if (outer.bottom <= 0 || outer.top >= innerHeight) continue;
      for (const box of textBoxes(el)) {
        if (box.bottom <= 0 || box.top >= innerHeight) continue;
        if (box.right > width + 1 && !scrollsSideways(el) && !pinned(el)) {
          findings.add(`text runs past the right edge of the viewport by ${Math.round(box.right - width)}px: ${name(el)}`);
          break;
        }
        const seen = visiblePart(el, box);
        if (!seen) continue;
        const x = (Math.max(seen.left, 0) + Math.min(seen.right, width)) / 2;
        const y = (Math.max(seen.top, 0) + Math.min(seen.bottom, innerHeight)) / 2;
        if (x <= 0 || x >= width || y <= 0 || y >= innerHeight) continue;
        const hit = document.elementFromPoint(x, y);
        if (!hit || el.contains(hit) || hit.contains(el) || pinned(hit) || !paints(hit)) continue;
        findings.add(`text is painted under ${name(hit)}: ${name(el)}`);
        break;
      }
    }
  }

  // Lines of a control's own text; an icon beside the label is not a second line.
  const lineCount = (el) => {
    const boxes = [];
    const walker = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    for (let node = walker.nextNode(); node; node = walker.nextNode()) {
      if (!node.textContent.trim()) continue;
      const range = document.createRange();
      range.selectNodeContents(node);
      boxes.push(...[...range.getClientRects()].filter((box) => box.width > 1));
    }
    boxes.sort((a, b) => a.top - b.top);
    let lines = 0;
    let lineBottom = -Infinity;
    for (const box of boxes) {
      if (box.top >= lineBottom - 3) {
        lines++;
        lineBottom = box.bottom;
      } else {
        lineBottom = Math.max(lineBottom, box.bottom);
      }
    }
    return lines;
  };

  function checkPage(texts, findings) {
    const root = document.documentElement;
    if (root.scrollWidth > root.clientWidth + 1) {
      const wide = [...document.body.querySelectorAll("*")].filter((el) =>
        shown(el) && !pinned(el) && !scrollsSideways(el) && el.getBoundingClientRect().right > root.clientWidth + 1);
      const outermost = wide.filter((el) => !wide.includes(el.parentElement)).slice(0, 5);
      findings.add(`the page scrolls sideways by ${root.scrollWidth - root.clientWidth}px; widest: ${outermost.map(name).join(", ") || "not found"}`);
    }

    for (const el of document.querySelectorAll(CONTROLS)) {
      if (!shown(el)) continue;
      const lines = lineCount(el);
      if (lines > 1) findings.add(`label wraps onto ${lines} lines: ${name(el)}`);
    }

    for (const el of texts) {
      const style = getComputedStyle(el);
      const cut = ["hidden", "clip"].includes(style.overflowX) || ["hidden", "clip"].includes(style.overflowY);
      const clamped = style.textOverflow === "ellipsis" || (style.webkitLineClamp && style.webkitLineClamp !== "none");
      if (cut && !clamped && (el.scrollWidth > el.clientWidth + 1 || el.scrollHeight > el.clientHeight + 1)) {
        findings.add(`text is cut off by its own box, with no ellipsis or way to the rest: ${name(el)}`);
      }
    }

    for (const img of document.images) {
      if (img.complete && img.naturalWidth === 0 && (img.currentSrc || img.getAttribute("src"))) {
        findings.add(`image did not load: ${img.currentSrc || img.getAttribute("src")}`);
      }
    }

    const stuck = [...document.body.querySelectorAll("*")].filter((el) => {
      const style = getComputedStyle(el);
      return ["sticky", "fixed"].includes(style.position) && style.top !== "auto" && shown(el);
    });
    for (const [i, a] of stuck.entries()) {
      for (const b of stuck.slice(i + 1)) {
        if (a.contains(b) || b.contains(a) || getComputedStyle(a).top !== getComputedStyle(b).top) continue;
        const ra = a.getBoundingClientRect();
        const rb = b.getBoundingClientRect();
        if (ra.left < rb.right && rb.left < ra.right) {
          findings.add(`${name(a)} and ${name(b)} both stick at top: ${getComputedStyle(a).top}; one slides under the other`);
        }
      }
    }
  }

  // The window, or in an app shell that keeps the window still, its largest
  // scrolling region.
  const scroller = () => {
    const root = document.scrollingElement || document.documentElement;
    if (root.scrollHeight > innerHeight + 1) return root;
    const regions = [...document.body.querySelectorAll("*")].filter((el) =>
      ["auto", "scroll"].includes(getComputedStyle(el).overflowY) && el.scrollHeight > el.clientHeight + 1 && shown(el));
    const area = (el) => el.clientWidth * el.clientHeight;
    return regions.sort((a, b) => area(b) - area(a))[0] || root;
  };

  async function layout() {
    await frames();
    const began = performance.now();
    const findings = new Set();
    const texts = textElements();
    const region = scroller();
    const isRoot = region === (document.scrollingElement || document.documentElement);
    const start = region.scrollTop;
    const step = Math.max(200, Math.floor(region.clientHeight * 0.9));
    let screens = 0;
    let partial = false;
    for (let y = 0; ; y += step) {
      // Reading a box forces layout, so the new scroll position is measured at once.
      region.scrollTop = y;
      checkScreen(texts, findings);
      screens++;
      if (y + region.clientHeight >= region.scrollHeight) break;
      if (screens >= 60 || performance.now() - began > 3000) {
        partial = true;
        break;
      }
    }
    checkPage(texts, findings);
    region.scrollTop = start;
    return {
      viewport: `${innerWidth}x${innerHeight}`,
      scrolled: isRoot ? "page" : name(region),
      screens,
      partial,
      ms: Math.round(performance.now() - began),
      findings: [...findings].slice(0, MAX_FINDINGS),
      truncated: findings.size > MAX_FINDINGS,
    };
  }

  const FOCUSABLE = 'a[href], button, input, select, textarea, summary, [tabindex]:not([tabindex="-1"]), [contenteditable="true"]';
  const LOOK = ["outlineStyle", "outlineWidth", "outlineColor", "boxShadow", "borderColor", "backgroundColor", "color", "textDecorationLine"];
  const styleOf = (style) => LOOK.map((key) => (key === "outlineWidth" && style.outlineStyle === "none" ? "0px" : style[key])).join("|");
  // A ring can also be drawn by a pseudo-element or by the parent through :focus-within.
  const look = (el) => [
    styleOf(getComputedStyle(el)),
    styleOf(getComputedStyle(el, "::before")),
    styleOf(getComputedStyle(el, "::after")),
    el.parentElement ? styleOf(getComputedStyle(el.parentElement)) : "",
  ].join("/");

  function rest() {
    document.activeElement?.blur?.();
    // Browsers also put scroll containers in the Tab order.
    const scrollers = [...document.body.querySelectorAll("*")].filter((el) =>
      ["auto", "scroll"].includes(getComputedStyle(el).overflowX) || ["auto", "scroll"].includes(getComputedStyle(el).overflowY));
    const all = new Set([...document.querySelectorAll(FOCUSABLE), ...scrollers]);
    window.__uiProbeRest = new Map([...all].map((el) => [el, look(el)]));
    return { remembered: window.__uiProbeRest.size };
  }

  function focus() {
    const el = document.activeElement;
    if (!el || el === document.body) return { focused: null, note: "focus is on the page body or has left the page" };
    const before = window.__uiProbeRest?.get(el);
    const box = el.getBoundingClientRect();
    const hit = document.elementFromPoint(box.left + box.width / 2, box.top + box.height / 2);
    return {
      focused: name(el),
      indicator: before === undefined ? "unknown: call uiProbe.rest() before the first Tab" : before !== look(el),
      hiddenUnder: hit && !el.contains(hit) && !hit.contains(el) && pinned(hit) ? name(hit) : null,
      inViewport: box.bottom > 0 && box.top < innerHeight && box.right > 0 && box.left < innerWidth,
    };
  }

  // Keyed by attributes that scripts, tests, and autofill read, never by position.
  // Framework handlers live in JavaScript, not the DOM, so only inline on* attributes
  // show up; a moved click handler is not caught here.
  function inventory() {
    const required = new Set();
    const soft = new Set();
    for (const a of document.querySelectorAll("a[href]")) required.add(`link ${a.getAttribute("href")}`);
    for (const form of document.forms) required.add(`form ${form.getAttribute("action") || ""} ${form.id || form.getAttribute("name") || ""}`.trim());
    for (const field of document.querySelectorAll("input, select, textarea, button[name]")) {
      const key = field.getAttribute("name") || field.id;
      if (key) required.add(`field ${key} ${field.getAttribute("type") || field.tagName.toLowerCase()}`);
    }
    for (const el of document.querySelectorAll("[data-testid], [data-test], [data-cy]")) {
      required.add(`test hook ${el.getAttribute("data-testid") || el.getAttribute("data-test") || el.getAttribute("data-cy")}`);
    }
    for (const el of document.querySelectorAll("*")) {
      for (const attr of el.getAttributeNames()) {
        if (attr.startsWith("on")) required.add(`handler ${attr} on ${el.id || el.getAttribute("name") || el.tagName.toLowerCase()}`);
      }
    }
    for (const el of document.querySelectorAll("[id]")) {
      if (!/[:]|^radix-|^headlessui-|^react-aria/.test(el.id)) soft.add(`id ${el.id}`);
    }
    for (const h of document.querySelectorAll("h1, h2, h3, h4, h5, h6")) {
      const text = h.textContent.trim().replace(/\s+/g, " ");
      if (text) soft.add(`${h.tagName.toLowerCase()} ${text.slice(0, 80)}`);
    }
    for (const img of document.images) soft.add(`image ${img.getAttribute("src") || ""} alt="${img.getAttribute("alt") ?? "(none)"}"`);
    return { url: location.pathname + location.search, viewport: `${innerWidth}x${innerHeight}`, required: [...required].sort(), soft: [...soft].sort() };
  }

  window.uiProbe = { layout, rest, focus, inventory };
  return "uiProbe ready";
})();
