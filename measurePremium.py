# measure.py - YouTube Premium (Usando sesión guardada)
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        
        # Le decimos a Playwright que cargue tu sesión Premium
        # Como GMT copia los archivos a /app, la ruta es esta:
        context = browser.new_context(storage_state="/app/premium_state.json")
        page = context.new_page()

        # --- VIDEO 1 ---
        page.goto("https://youtu.be/8YxQLBRbpJI?si=_cKbfymj5srQp6Et", timeout=60000, wait_until="domcontentloaded")
        # Ya no necesitamos buscar el botón de cookies porque al estar logueado ya están aceptadas
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
