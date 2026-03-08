*** Settings ***
Library    ../driver_service.py
Library    String
Resource    gui_action_keywords.robot
#Library    SeleniumLibrary    screenshot_on_failure=False
Library    SeleniumLibrary    run_on_failure=Nothing

*** Variables ***
${URL}               https://opensource-demo.orangehrmlive.com/web/index.php/auth/login
${USERNAME_FIELD}    xpath=//input[@name='username123']
${PASSWORD_FIELD}    xpath=//input[@name='password123']
${SIGN_IN}           xpath=//button[@type='submit']    

*** Keywords ***
Kw Open Login Page
    ${service}=    Get Chrome Service
    Log to console    Launching Chrome browser.
    Open Browser    ${URL}    chrome    service=${service}
    sleep           15s
    Log to console    Browser launched successfully.
    Log to console    Maximizing browser window.
    Maximize Browser Window   


# Kw Input Username  
#     [Arguments]    ${username_value}
#     KW Input Text with self healing    ${USERNAME_FIELD}    ${username_value}

Kw input username 
    [Arguments]    ${username_value}
    KW Input Text with self healing    ${USERNAME_FIELD}    ${username_value}


Kw input password 
    [Arguments]    ${password_value}
    KW Input Text with self healing    ${PASSWORD_FIELD}    ${password_value}

kW click login button
    KW Click Button with self healing    ${SIGN_IN}    
    sleep           20s


# Kw Input Password    
#     [Arguments]   ${password}
#     Input Text    ${PASSWORD_FIELD}    ${password}

# Kw Click Login Button
#     Click Button    ${SIGN_IN}    

# Kw Verify Successful Login
#     Wait Until Element Is Visible    ${DASHBOARD_LOGO}    timeout=20s
#     Element Should Be Visible        ${DASHBOARD_LOGO}
    
# kW Get Page Source
#     ${page_source}=    Get Source
#     [Return]    ${page_source}    

# Kw Close All Browsers
#     Close All Browsers


# Kw Get Locator Details
#     [Arguments]    ${locator}
#     ${locator_type}    ${locator_value}=    Split String    ${locator}    =   1
#     Log To Console    Locator Type: ${locator_type}
#     Log To Console    Locator Value: ${locator_value}
#     [Return]    ${locator_type}    ${locator_value}    