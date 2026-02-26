# measure.py - YouTube Free
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        # Lanzamos Chromium en modo headless (sin interfaz gráfica para el contenedor)
      browser = p.chromium.launch(headless=True)
      context = browser.new_context()
      page = context.new_page()

        # Vamos a un video (elige uno que sepas que tiene anuncios al principio)
      page.goto("https://www.youtube.com/watch?v=8YxQLBRBpJI&list=PLv8ReycPcD1ee1htykmUvTdQh2HMYbRWo ")
        
        # NOTA: En Europa, YouTube suele pedir aceptar cookies. 
        # Intentamos hacer clic en "Aceptar todo" si aparece el botón.
      try:
          page.click("button:has-text('Accept all')", timeout=5000)
      except:
          pass # Si no aparece, seguimos

        # Reproducimos durante 60 segundos
      time.sleep(60)

      browser.close()

if __name__ == "__main__":
    run()
