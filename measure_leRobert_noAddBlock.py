# measure.py - "le robert" dictionary
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        # Launch Chromium in headless mode (without graphical interface for the container)
        browser = p.chromium.launch(headless=True)
        #browser = p.chromium.launch(headless=False)
        context = browser.new_context()
        page = context.new_page()


        # Go to the main page
        page.goto("https://dictionnaire.lerobert.com", timeout=60000, wait_until="domcontentloaded")
        
        # Try to accept cookies if they appear
        try:
            page.click("button:has-text('Accepter & Fermer')", timeout=5000)
        except:
            pass # If it does not appear, continue
        
        # Search for a word
        page.goto("https://dictionnaire.lerobert.com/definition/iel", timeout=60000, wait_until="domcontentloaded")
        time.sleep(60)
        
        # Search for a word
        page.goto("https://dictionnaire.lerobert.com/definition/caca", timeout=60000, wait_until="domcontentloaded")
        time.sleep(60)

        # Search for a word
        page.goto("https://dictionnaire.lerobert.com/definition/ascenseur", timeout=60000, wait_until="domcontentloaded")
        time.sleep(60)

        # Search for synonyms of a word
        page.goto("https://dictionnaire.lerobert.com/synonymes/cool", timeout=60000, wait_until="domcontentloaded")
        time.sleep(60)

        # Search for synonyms of a word
        page.goto("https://dictionnaire.lerobert.com/synonymes/caca", timeout=60000, wait_until="domcontentloaded")
        time.sleep(60)

      browser.close()

if __name__ == "__main__":
    run()
