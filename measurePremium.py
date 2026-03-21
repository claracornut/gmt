# measure.py - YouTube Premium (Using saved session)
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        # Tell Playwright to load your Premium session
        # Since GMT copies the files to /app, this is the path:
context = browser.new_context(storage_state="/app/premium_state.json")
        page = context.new_page()

        # --- VIDEO 1 ---
        page.goto("https://youtu.be/8YxQLBRbpJI?si=_cKbfymj5srQp6Et", timeout=60000, wait_until="domcontentloaded")

        # We no longer need to look for the cookies button because,
        # since we are logged in, they are already accepted

        time.sleep(161)

        # --- VIDEO 2 ---
        page.goto("https://youtu.be/cX24KLL8klY?si=RsC-1I7-41AomOot", timeout=60000, wait_until="domcontentloaded")
        time.sleep(186)

        # --- VIDEO 3 ---
        page.goto("https://youtu.be/Y4J_NYAQQEQ?si=j-uW3sTEo6I8c9yE", timeout=60000, wait_until="domcontentloaded")
        time.sleep(181)

        context.close()
        browser.close()

if __name__ == "__main__":
    run()
