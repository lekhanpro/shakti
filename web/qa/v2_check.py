from pathlib import Path

from playwright.sync_api import sync_playwright


ROOT = Path(__file__).resolve().parent.parent
REVIEW = ROOT / ".impeccable" / "review"
REVIEW.mkdir(parents=True, exist_ok=True)


def check_page(page, width: int, height: int, screenshot_name: str) -> None:
    page.set_viewport_size({"width": width, "height": height})
    page.goto("http://127.0.0.1:3000", wait_until="domcontentloaded")
    page.wait_for_timeout(5000)
    assert page.locator("h1").inner_text() == "Three presses.\nA whole network."
    assert page.locator("#trigger").is_visible()
    assert page.locator("#story").is_visible()
    assert page.locator("#network").is_visible()
    assert page.locator("#map").is_visible()
    assert page.locator("#ai").is_visible()
    assert page.locator("#helplines").is_visible()
    assert page.locator("#faq").is_visible()
    assert page.locator("#download").is_visible()
    assert page.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1")
    height = page.evaluate("document.body.scrollHeight")
    for _ in range(0, height + 1, 780):
        page.mouse.wheel(0, 780)
        page.wait_for_timeout(120)
    page.evaluate("window.scrollTo({top: 0, behavior: 'instant'})")
    page.wait_for_timeout(1500)
    page.screenshot(path=str(REVIEW / screenshot_name), full_page=True)


with sync_playwright() as playwright:
    browser = playwright.chromium.launch(
        headless=True,
        executable_path=r"C:\Users\lekhan hr\AppData\Local\ms-playwright\chromium-1228\chrome-win64\chrome.exe",
    )
    desktop = browser.new_page(viewport={"width": 1440, "height": 900})
    desktop.on("pageerror", lambda error: print("PAGE_ERROR", error))
    desktop.on("console", lambda message: print("CONSOLE", message.type, message.text) if message.type == "error" else None)
    check_page(desktop, 1440, 900, "desktop.png")

    probe = browser.new_page(viewport={"width": 1440, "height": 900})
    probe.goto("http://127.0.0.1:3000", wait_until="domcontentloaded")
    probe.wait_for_timeout(2000)
    trigger = probe.locator('button[aria-label="Power button. Press three times quickly."]')
    trigger.scroll_into_view_if_needed()
    for _ in range(3):
        trigger.click(force=True)
        probe.wait_for_timeout(100)
    assert probe.get_by_text("Sending SOS in").is_visible()
    probe.get_by_role("button", name="Cancel").click()
    assert probe.get_by_text("Press the side key 3 times").is_visible()
    probe.close()

    desktop.goto("http://127.0.0.1:3000/track/demo", wait_until="domcontentloaded")
    desktop.wait_for_timeout(1200)
    assert desktop.locator("body").inner_text()

    mobile = browser.new_page(viewport={"width": 390, "height": 844}, reduced_motion="reduce")
    check_page(mobile, 390, 844, "mobile.png")
    mobile.get_by_role("button", name="Open menu").click()
    assert mobile.locator("#mobile-nav").is_visible()
    mobile.close()
    desktop.close()
    browser.close()
