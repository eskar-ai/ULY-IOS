#!/usr/bin/env python3
"""Capture web demo frames for App Store marketing screenshot composition.

Uses Playwright + system Chrome against the public /demo/ (or DEMO_URL).
"""

from __future__ import annotations

import os
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

OUT = Path("/opt/cursor/artifacts/screenshots")
DEMO_URL = os.environ.get("DEMO_URL", "https://eskar-ai.github.io/ULY-IOS/demo/")
VIEWPORT = {"width": 430, "height": 932}  # phone-ish


def shot(page, name: str) -> Path:
    OUT.mkdir(parents=True, exist_ok=True)
    dest = OUT / name
    page.screenshot(path=str(dest), full_page=False, type="png")
    print("captured", dest)
    return dest


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(
            executable_path="/usr/local/bin/google-chrome",
            headless=True,
            args=["--disable-dev-shm-usage"],
        )
        context = browser.new_context(
            viewport=VIEWPORT,
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()
        page.goto(DEMO_URL, wait_until="networkidle", timeout=120_000)
        page.wait_for_selector("#keyboard", timeout=60_000)
        # Wait for lexicon
        page.wait_for_function(
            """() => {
              const s = document.querySelector('#status');
              return s && !/loading/i.test(s.textContent || '');
            }""",
            timeout=90_000,
        )
        time.sleep(0.5)

        # Light theme empty / setup-like
        page.evaluate("""() => {
          localStorage.setItem('uyghurlatin.themePreference', 'light');
          location.reload();
        }""")
        page.wait_for_selector("#keyboard", timeout=60_000)
        page.wait_for_function(
            """() => {
              const s = document.querySelector('#status');
              return s && !/loading/i.test(s.textContent || '');
            }""",
            timeout=90_000,
        )
        time.sleep(0.4)
        shot(page, "uly-theme-light.png")
        # Alias names expected by make_store_screenshots
        shot(page, "uly-theme-system.png")

        # Type for suggestions
        editor = page.locator("#editor")
        editor.click()
        editor.fill("")
        editor.type("uygh", delay=40)
        time.sleep(0.6)
        shot(page, "uly-theme-light-suggestions.png")

        # Dark + suggestions
        page.evaluate("""() => {
          localStorage.setItem('uyghurlatin.themePreference', 'dark');
        }""")
        # click theme until dark if button cycles
        for _ in range(3):
            btn = page.locator("#themeCycle")
            if btn.count():
                btn.click()
                time.sleep(0.2)
        # force via class/attr if app exposes data-theme
        page.evaluate("""() => {
          document.documentElement.dataset.theme = 'dark';
          document.body.classList.add('theme-dark');
          localStorage.setItem('uyghurlatin.themePreference', 'dark');
          window.dispatchEvent(new Event('storage'));
        }""")
        # Reload to apply preference cleanly
        page.reload(wait_until="networkidle")
        page.wait_for_selector("#keyboard", timeout=60_000)
        page.wait_for_function(
            """() => {
              const s = document.querySelector('#status');
              return s && !/loading/i.test(s.textContent || '');
            }""",
            timeout=90_000,
        )
        time.sleep(0.4)
        shot(page, "uly-theme-dark.png")

        editor = page.locator("#editor")
        editor.click()
        editor.fill("")
        editor.type("uygh", delay=40)
        time.sleep(0.7)
        shot(page, "uly-theme-dark-suggestions.png")

        # Spell-check style: type misspelling
        editor.fill("")
        editor.type("bugun", delay=40)
        time.sleep(0.8)
        shot(page, "uly-corrected-bugun.png")

        browser.close()
    print("done →", OUT)


if __name__ == "__main__":
    main()
