# measure.py - YouTube AdBlock (uBlock Origin)
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:

        # Since GMT copies the files to /app in the Docker container,
        # the path will be this one:

        path_to_extension = "/app/adblockplus"


        # Launch Chromium using a persistent context
        # so that the extension can be injected
        
        context = p.chromium.launch_persistent_context(
            user_data_dir="/tmp/playwright-user-data", # Temporary folder required
            headless=True,
            args=[
                f"--disable-extensions-except={path_to_extension}",
                f"--load-extension={path_to_extension}",
                "--headless=new"
            ]
        )

        # In a persistent context, the browser already opens one page by default
        page = context.pages[0]

        # --- VIDEO 1 ---
        page.goto("https://youtu.be/8YxQLBRBpJI?si=WqOA2tSgWDM5BMKB", timeout=60000, wait_until="domcontentloaded")

        # Try to accept cookies if they appear
        try:
            page.click("button:has-text('Accept all')", timeout=5000)
        except:
            pass
        try:
            page.click("button:has-text('Aceptar todo')", timeout=5000)
        except:
            pass # If it does not appear, continue
        try:
            page.click("button:has-text('Tout accepter')", timeout=5000)
        except:
            pass # If it does not appear, continue
    
        time.sleep(161)

        # --- VIDEO 2 ---
        page.goto("https://youtu.be/cX24KlL8klY?si=havUAEjKDooz68T_", timeout=60000, wait_until="domcontentloaded")
        time.sleep(186)

        # --- VIDEO 3 ---
        page.goto("https://youtu.be/Y4J_NYAQQEQ?si=BLcMRRYQMqy0-23l", timeout=60000, wait_until="domcontentloaded")
        time.sleep(181)

        # Close the context
        context.close()

if __name__ == "__main__":
    run()
