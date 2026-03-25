# measure.py - YouTube Free
from playwright.sync_api import sync_playwright
import time

def run():
    with sync_playwright() as p:
        # Launch Chromium in headless mode (without graphical interface for the container)
      browser = p.chromium.launch(headless=True)
        #browser = p.chromium.launch(headless=False)
      context = browser.new_context()
      page = context.new_page()


        # Go to a video (choose one that you know has ads at the beginning)
      page.goto("https://youtu.be/8YxQLBRBpJI?si=WqOA2tSgWDM5BMKB", timeout=60000, wait_until="domcontentloaded")
        
        # NOTE: In Europe, YouTube usually asks to accept cookies.        
        # We try to click "Accept all" if the button appears.
      try:
          page.click("button:has-text('Accept all')", timeout=5000)
      except:
          pass # If it does not appear, continue
          
      try:
          page.click("button:has-text('Aceptar todo')", timeout=5000)
      except:
          pass # If it does not appear, continue

      try:
          page.click("button:has-text('Tout accepter')", timeout=5000)
      except:
          pass # If it does not appear, continue


      # Play for 60 seconds
      time.sleep(161)
      #time.sleep(15)
      
      page.goto("https://youtu.be/cX24KlL8klY?si=havUAEjKDooz68T_", timeout=60000, wait_until="domcontentloaded")
      
      time.sleep(186)
      
      page.goto("https://youtu.be/Y4J_NYAQQEQ?si=BLcMRRYQMqy0-23l", timeout=60000, wait_until="domcontentloaded")
      
      time.sleep(181)

      browser.close()

if __name__ == "__main__":
    run()
