*** Settings ***
Library    ../driver_service.py
Library    String
Resource    gui_action_keywords.robot
#Library    SeleniumLibrary    screenshot_on_failure=False
Library    SeleniumLibrary    run_on_failure=Nothing

*** Variables ***
${ORANGE_HRM_LOGO}   xpath=//img[@alt='client brand banner']

*** Keywords ***
Kw Verify Dashboard logo is visible
    KW Element should be visible with self healing    ${ORANGE_HRM_LOGO}
    sleep   8s
