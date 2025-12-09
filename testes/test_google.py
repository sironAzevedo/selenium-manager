from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time

def main():
    # URL do Selenium Standalone no seu container
    SELENIUM_URL = "http://localhost:4444/wd/hub"

    print("[TESTE] Conectando ao Selenium...")

    # Configuração do Chrome
    chrome_options = webdriver.ChromeOptions()
    chrome_options.add_argument("--start-maximized")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")

    # Instancia o WebDriver remoto
    driver = webdriver.Remote(
        command_executor=SELENIUM_URL,
        options=chrome_options
    )

    print("[TESTE] Abrindo Google...")
    driver.get("https://www.google.com")

    time.sleep(2)

    # Aceitar cookies (caso apareça)
    try:
        btn = driver.find_element(By.XPATH, "//button[contains(., 'Aceitar')]")
        btn.click()
        time.sleep(1)
    except:
        pass  # ignora se não existir

    print("[TESTE] Digitando busca...")
    campo = driver.find_element(By.NAME, "q")
    campo.send_keys("Selenium Grid Python")
    campo.send_keys(Keys.RETURN)

    time.sleep(3)

    print("[TESTE] Título atual:", driver.title)

    # Screenshot opcional
    driver.save_screenshot("google_test.png")
    print("[TESTE] Screenshot salvo: google_test.png")

    driver.quit()
    print("[TESTE] Finalizado!")

if __name__ == "__main__":
    main()
