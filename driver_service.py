from selenium.webdriver.chrome.service import Service

# Robot Framework will discover this function as the keyword "Get Chrome Service"
def get_chrome_service():
    # Adjust path if needed relative to your test run directory
    return Service(executable_path="./drivers/chromedriver")