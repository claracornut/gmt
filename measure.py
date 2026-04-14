# measure.py - YouTube Free (Usando sesión guardada)
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True,args=["--autoplay-policy=no-user-gesture-required"])
        
        # Le decimos a Playwright que cargue tu sesión Premium
        # Como GMT copia los archivos a /app, la ruta es esta:
        context = browser.new_context(storage_state="/app/free_state.json")
        page = context.new_page()

        # --- VIDEO 1 ---
        page.goto("https://youtu.be/8YxQLBRBpJI?si=_cKbfymj5srQp6Et", timeout=60000, wait_until="domcontentloaded")
        # Ya no necesitamos buscar el botón de cookies porque al estar logueado ya están aceptadas
        time.sleep(166) #+5s
        #time.sleep(15)
        #page.screenshot(path="pantallazo_debug1.png")

        # --- VIDEO 2 ---
        page.goto("https://youtu.be/cX24KlL8klY?si=RsC-1I7-41AomOot", timeout=60000, wait_until="domcontentloaded")
        time.sleep(191) #+5s
        #time.sleep(15)
        #page.screenshot(path="pantallazo_debug2.png")

        # --- VIDEO 3 ---
        page.goto("https://youtu.be/Y4J_NYAQQEQ?si=j-uW3sTEo6I8c9yE", timeout=60000, wait_until="domcontentloaded")
        time.sleep(186) #+5s
        #time.sleep(15)
        #page.screenshot(path="pantallazo_debug3.png")

        context.close()
        browser.close()

if __name__ == "__main__":
    run()
