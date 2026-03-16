# measure.py - YouTube Free
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        # Lanzamos Chromium en modo headless (sin interfaz gráfica para el contenedor)
      browser = p.chromium.launch(headless=True)
      #browser = p.chromium.launch(headless=False)
      context = browser.new_context()
      page = context.new_page()

        # Vamos a un video (elige uno que sepas que tiene anuncios al principio)
      page.goto("https://youtu.be/8YxQLBRBpJI?si=_cKbfymj5srQp6Et", timeout=60000, wait_until="domcontentloaded")
        
        # NOTA: En Europa, YouTube suele pedir aceptar cookies. 
        # Intentamos hacer clic en "Aceptar todo" si aparece el botón.
      try:
          page.click("button:has-text('Accept all')", timeout=5000)
      except:
          pass # Si no aparece, seguimos
          
      try:
          page.click("button:has-text('Aceptar todo')", timeout=5000)
      except:
          pass # Si no aparece, seguimo

        # Reproducimos durante 60 segundos
      time.sleep(161)
      #time.sleep(15)
      
      page.goto("https://youtu.be/cX24KlL8klY?si=RsC-1I7-41AomOot", timeout=60000, wait_until="domcontentloaded")
      
      time.sleep(186)
      
      page.goto("https://youtu.be/Y4J_NYAQQEQ?si=j-uW3sTEo6I8c9yE", timeout=60000, wait_until="domcontentloaded")
      
      time.sleep(181)

      browser.close()

if __name__ == "__main__":
    run()
