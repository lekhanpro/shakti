"""Browser smoke check for the landing page and the tracker route.

Assertion-based gate, meant to fail loudly in CI. qa/review.py is the companion
visual pass that captures the batched review screenshots.

Two notes that have bitten this script before:

- The origin must be localhost. `next dev` binds localhost, and loading
  127.0.0.1 fails the HMR websocket handshake, which blocks hydration: every
  assertion about an interactive control then fails against a page whose client
  effects never ran, and every screenshot shows the un-hydrated markup.
- The Chromium build is discovered, not pinned. A hardcoded build number rots
  the next time Playwright updates.

Run (from web/, with the dev or prod server already up):  py qa/v2_check.py
"""

from __future__ import annotations

import sys
from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
REVIEW = ROOT / ".impeccable" / "review"
REVIEW.mkdir(parents=True, exist_ok=True)

BASE = "http://localhost:3000"

# Anchors the page is expected to expose, in reading order.
SECTIONS = ["response", "trigger", "network", "features", "map", "ai", "helplines", "faq", "download"]

HEADLINE = "Your people.\nOne signal away."


def chromium_path() -> str | None:
    """Newest installed Playwright Chromium, or None to use the bundled one."""
    cache = Path.home() / "AppData/Local/ms-playwright"
    builds = sorted(
        cache.glob("chromium-*/chrome-win64/chrome.exe"),
        key=lambda p: int(p.parent.parent.name.split("-")[1]),
        reverse=True,
    )
    return str(builds[0]) if builds else None


def check_page(page, width: int, height: int, screenshot_name: str) -> None:
    page.set_viewport_size({"width": width, "height": height})
    page.goto(BASE, wait_until="domcontentloaded")
    page.wait_for_timeout(5000)

    assert page.locator("h1").inner_text() == HEADLINE, page.locator("h1").inner_text()
    for anchor in SECTIONS:
        assert page.locator(f"#{anchor}").is_visible(), f"#{anchor} missing"

    # The globe carries the hero, so its own pieces are part of the smoke check.
    assert page.locator(".globe-stage").is_visible()
    assert page.locator(".globe-chip").count() == 5
    assert page.locator(".globe-marker").count() == 5
    assert page.locator(".globe-readout").inner_text().strip()

    assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1"), "horizontal overflow"

    total = page.evaluate("document.body.scrollHeight")
    for _ in range(0, total + 1, 780):
        page.mouse.wheel(0, 780)
        page.wait_for_timeout(120)
    page.evaluate("window.scrollTo({top: 0, behavior: 'instant'})")
    page.wait_for_timeout(1500)
    page.screenshot(path=str(REVIEW / screenshot_name), full_page=True)


def check_globe(page) -> None:
    """Selecting a guardian and dropping the link must change the readout."""
    page.goto(BASE, wait_until="domcontentloaded")
    page.wait_for_timeout(4000)

    before = page.locator(".globe-readout").inner_text()
    page.get_by_role("button", name="Cousin").click()
    page.wait_for_timeout(1200)
    assert page.locator(".globe-readout").inner_text() != before, "selecting a guardian changed nothing"
    assert "Dubai" in page.locator(".globe-readout").inner_text()

    page.locator(".globe-link").click()
    page.wait_for_timeout(600)
    readout = page.locator(".globe-readout").inner_text()
    assert "waits for internet" in readout, readout
    # Carrier SMS is independent of the internet request: the page must keep
    # saying so with the link dropped.
    assert "cellular" in readout, readout


def check_trigger(page) -> None:
    """The power-key demo still opens and cancels its countdown."""
    page.goto(BASE, wait_until="domcontentloaded")
    page.wait_for_timeout(2500)
    trigger = page.locator('button[aria-label="Power button. Press three times quickly."]')
    trigger.scroll_into_view_if_needed()
    for _ in range(3):
        trigger.click(force=True)
        page.wait_for_timeout(100)
    assert page.get_by_text("Sending SOS in").is_visible()
    page.get_by_role("button", name="Cancel").click()
    assert page.get_by_text("Press the side key 3 times").is_visible()


def check_no_webgl(browser) -> None:
    """Without WebGL the server-rendered hemisphere stays, and copy survives."""
    context = browser.new_context(viewport={"width": 1440, "height": 900})
    context.add_init_script(
        """
        const real = HTMLCanvasElement.prototype.getContext;
        HTMLCanvasElement.prototype.getContext = function (kind, ...rest) {
          if (String(kind).includes('webgl')) return null;
          return real.call(this, kind, ...rest);
        };
        """
    )
    page = context.new_page()
    page.goto(BASE, wait_until="domcontentloaded")
    page.wait_for_timeout(3500)
    assert page.locator("h1").inner_text() == HEADLINE
    assert page.locator(".globe-stage").get_attribute("data-live") == "false"
    assert page.locator(".globe-poster").count() == 1
    assert page.locator(".globe-chip").count() == 5
    context.close()


failures: list[str] = []

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, executable_path=chromium_path())

    desktop = browser.new_page(viewport={"width": 1440, "height": 900})
    desktop.on("pageerror", lambda error: failures.append(f"PAGE_ERROR {error}"))
    desktop.on(
        "console",
        # The dev server's HMR socket is noisy and not a page defect.
        lambda m: failures.append(f"CONSOLE {m.text}")
        if m.type == "error" and "hmr" not in m.text.lower() and "websocket" not in m.text.lower()
        else None,
    )
    check_page(desktop, 1440, 900, "desktop.png")
    check_globe(desktop)
    check_trigger(desktop)

    check_no_webgl(browser)

    # The tracker route keeps its own styling and behaviour.
    desktop.goto(f"{BASE}/track/demo", wait_until="domcontentloaded")
    desktop.wait_for_timeout(1200)
    assert desktop.locator("body").inner_text()

    mobile = browser.new_page(viewport={"width": 390, "height": 844}, reduced_motion="reduce")
    check_page(mobile, 390, 844, "mobile.png")
    mobile.get_by_role("button", name="Open navigation").click()
    assert mobile.locator("#s-mobile-nav").is_visible()
    mobile.close()

    desktop.close()
    browser.close()

if failures:
    print("FAILURES:")
    for item in dict.fromkeys(failures):
        print(" ", item)
    sys.exit(1)

print("v2_check: all assertions passed")
