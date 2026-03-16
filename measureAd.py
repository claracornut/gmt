# measure.py - YouTube AdBlock (uBlock Origin)
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        # Como GMT copia los archivos a /app en el contenedor Docker, la ruta será esta:
        path_to_extension = "/app/ublock"

        # Lanzamos Chromium usando un contexto persistente para poder inyectar la extensión
        context = p.chromium.launch_persistent_context(
            user_data_dir="/tmp/playwright-user-data", # Carpeta temporal necesaria
            headless=True,
            args=[
                f"--disable-extensions-except={path_to_extension}",
                f"--load-extension={path_to_extension}",
                "--headless=new"
            ]
        )

        # En un contexto persistente, el navegador ya trae una página abierta por defecto
        page = context.pages[0]

        # --- VIDEO 1 ---
        page.goto("https://youtu.be/8YxQLBRbpJI?si=_cKbfymj5srQp6Et", timeout=60000, wait_until="domcontentloaded")
        
        # Intentamos aceptar cookies si salen
        try:
            page.click("button:has-text('Accept all')", timeout=5000)
        except:
            pass
            
        time.sleep(161)

        # --- VIDEO 2 ---
        page.goto("https://youtu.be/cX24KLL8klY?si=RsC-1I7-41AomOot", timeout=60000, wait_until="domcontentloaded")
        time.sleep(186)

        # --- VIDEO 3 ---
        page.goto("https://youtu.be/Y4J_NYAQQEQ?si=j-uW3sTEo6I8c9yE", timeout=60000, wait_until="domcontentloaded")
        time.sleep(181)

        # Cerramos el contexto
        context.close()

if __name__ == "__main__":
    run()
