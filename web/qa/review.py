"""Batched review capture for the landing page.

One render per viewport, so the checks share a page rather than paying for a
screenshot trip each. Origin is localhost on purpose: next dev binds localhost,
and 127.0.0.1 fails the HMR handshake, which blocks hydration and would make
every capture a picture of an unhydrated page.

Run (from web/):  py qa/review.py [out-dir]
"""

from __future__ import annotations

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / ".impeccable" / (sys.argv[1] if len(sys.argv) > 1 else "review")
OUT.mkdir(parents=True, exist_ok=True)
CHROME = Path.home() / "AppData/Local/ms-playwright/chromium-1248/chrome-win64/chrome.exe"
URL = "http://localhost:3000/"

SECTIONS = ["response", "trigger", "network", "features", "map", "ai", "helplines", "faq", "download"]

# Kills WebGL so the server-rendered poster path can be reviewed.
NO_WEBGL = """
const real = HTMLCanvasElement.prototype.getContext;
HTMLCanvasElement.prototype.getContext = function (kind, ...rest) {
  if (String(kind).includes('webgl')) return null;
  return real.call(this, kind, ...rest);
};
"""


def settle(page, label):
    """Let fonts, hydration and the arrival overlay finish before capturing."""
    page.wait_for_timeout(2500)
    intro = page.query_selector(".s-intro")
    phase = intro.get_attribute("data-phase") if intro else "gone"
    if intro and phase != "gone":
        page.wait_for_timeout(2500)
        intro = page.query_selector(".s-intro")
        phase = intro.get_attribute("data-phase") if intro else "gone"
    hydrated = page.evaluate("!!document.querySelector('.s-motion-toggle')")
    print(f"  [{label}] intro={phase} hydrated={hydrated}")
    return hydrated


def report(page, label):
    data = page.evaluate("""() => {
      const doc = document.documentElement;
      const stage = document.querySelector('.globe-stage');
      const canvas = document.querySelector('.globe-canvas');
      const poster = document.querySelector('.globe-poster');
      // SVG children are clipped by their own viewport, so a rotating sweep
      // reaching past it is not page overflow. documentElement.scrollWidth is
      // the real check; this list only names what to look at.
      const wide = [...document.querySelectorAll('.shakti-site *')]
        .filter(el => !(el instanceof SVGElement))
        .filter(el => el.getBoundingClientRect().right > window.innerWidth + 1)
        .slice(0, 6)
        .map(el => (el.tagName + '.' + String(el.className)).slice(0, 72));
      return {
        height: doc.scrollHeight,
        overflowX: doc.scrollWidth - window.innerWidth,
        live: stage ? stage.dataset.live : 'no-stage',
        canvas: canvas ? canvas.width + 'x' + canvas.height : 'none',
        posterShown: poster ? getComputedStyle(poster).display !== 'none' : null,
        markers: document.querySelectorAll('.globe-marker').length,
        chips: document.querySelectorAll('.globe-chip').length,
        readout: (document.querySelector('.globe-readout')?.textContent || '').slice(0, 90),
        wide,
      };
    }""")
    print(f"  [{label}] height={data['height']}px overflowX={data['overflowX']}px")
    print(f"  [{label}] globe live={data['live']} canvas={data['canvas']} poster={data['posterShown']}"
          f" markers={data['markers']} chips={data['chips']}")
    print(f"  [{label}] readout: {data['readout']}")
    if data["wide"]:
        print(f"  [{label}] !! overflowing: {data['wide']}")
    return data


def scroll_through(page):
    height = page.evaluate("document.body.scrollHeight")
    y = 0
    while y < height:
        page.mouse.wheel(0, 700)
        page.wait_for_timeout(80)
        y += 700
    page.evaluate("window.scrollTo({top: 0, behavior: 'instant'})")
    page.wait_for_timeout(900)


def capture(browser, width, height, tag, *, sections=False, init=None, reduced=False):
    context = browser.new_context(
        viewport={"width": width, "height": height},
        reduced_motion="reduce" if reduced else "no-preference",
        device_scale_factor=1,
    )
    if init:
        context.add_init_script(init)
    page = context.new_page()
    errors, console = [], []
    page.on("pageerror", lambda e: errors.append(str(e)[:200]))
    page.on("console", lambda m: console.append(f"{m.type}: {m.text[:160]}") if m.type == "error" else None)

    print(f"\n### {tag}  {width}x{height}")
    page.goto(URL, wait_until="domcontentloaded")
    settle(page, tag)
    page.screenshot(path=str(OUT / f"{tag}-hero.png"))
    scroll_through(page)
    report(page, tag)
    page.screenshot(path=str(OUT / f"{tag}.png"), full_page=True)

    if sections:
        for name in SECTIONS:
            if not page.query_selector(f"#{name}"):
                print(f"  !! #{name} missing")
                continue
            page.evaluate(f"document.getElementById('{name}').scrollIntoView({{block:'start',behavior:'instant'}})")
            page.wait_for_timeout(450)
            page.screenshot(path=str(OUT / f"{tag}-{name}.png"))

    hmr = sum(1 for c in console if "hmr" in c.lower() or "websocket" in c.lower())
    real = [c for c in console if "hmr" not in c.lower() and "websocket" not in c.lower()]
    if errors:
        print(f"  !! pageerror: {errors[:3]}")
    if real:
        print(f"  !! console: {real[:3]}")
    if hmr:
        print(f"  (ignored {hmr} dev HMR socket messages)")
    context.close()


def interact(browser):
    """Drive the globe's controls and confirm the readout follows."""
    context = browser.new_context(viewport={"width": 1440, "height": 900}, device_scale_factor=1)
    page = context.new_page()
    print("\n### interaction")
    page.goto(URL, wait_until="domcontentloaded")
    settle(page, "interact")

    before = page.inner_text(".globe-readout")
    chip = page.get_by_role("button", name="Cousin")
    chip.click()
    page.wait_for_timeout(1400)
    after = page.inner_text(".globe-readout")
    print(f"  chip pressed={chip.get_attribute('aria-pressed')}")
    print(f"  readout before: {before[:70]}")
    print(f"  readout after : {after[:70]}")
    print(f"  readout changed: {before != after}")
    page.screenshot(path=str(OUT / "interact-selected.png"))

    link = page.get_by_role("button", name="Tracker link on")
    link.click()
    page.wait_for_timeout(700)
    queued = page.query_selector(".globe-link")
    print(f"  link toggle -> '{queued.inner_text().strip()}' pressed={queued.get_attribute('aria-pressed')}")
    print(f"  readout now: {page.inner_text('.globe-readout')[:90]}")
    page.screenshot(path=str(OUT / "interact-offline.png"))

    # Drag the stage and confirm the pose actually moved.
    page.get_by_role("button", name="Cousin").click()
    page.wait_for_timeout(600)
    box = page.query_selector(".globe-stage").bounding_box()
    cx, cy = box["x"] + box["width"] / 2, box["y"] + box["height"] / 2
    first = page.evaluate("document.querySelector('.globe-origin').style.left")
    page.mouse.move(cx, cy)
    page.mouse.down()
    for step in range(1, 11):
        page.mouse.move(cx + step * 14, cy, steps=1)
        page.wait_for_timeout(16)
    page.mouse.up()
    page.wait_for_timeout(500)
    second = page.evaluate("document.querySelector('.globe-origin').style.left")
    print(f"  drag moved origin: {first} -> {second}  changed={first != second}")
    page.screenshot(path=str(OUT / "interact-dragged.png"))

    # Keyboard: sampled from a fresh load, so the order starts at the document
    # top instead of wherever the clicks above left focus.
    page.goto(URL, wait_until="domcontentloaded")
    settle(page, "keyboard")
    order = []
    for _ in range(26):
        page.keyboard.press("Tab")
        order.append(page.evaluate("""() => {
          const el = document.activeElement;
          if (!el) return 'none';
          return (el.getAttribute('aria-label') || el.innerText || el.tagName).trim().slice(0, 34).replace(/\\s+/g, ' ');
        }"""))
    print(f"  tab order: {order}")
    context.close()


with sync_playwright() as pw:
    browser = pw.chromium.launch(headless=True, executable_path=str(CHROME))
    capture(browser, 1440, 900, "desktop", sections=True)
    capture(browser, 390, 844, "mobile", sections=True)
    capture(browser, 1440, 900, "no-webgl", init=NO_WEBGL)
    capture(browser, 1440, 900, "reduced", reduced=True)
    interact(browser)
    browser.close()

print(f"\ndone -> {OUT}")
