*** Settings ***
Library    SeleniumLibrary
Library    ../driver_service.py

*** Variables ***
${URL}               https://opensource-demo.orangehrmlive.com/web/index.php/auth/login
${USERNAME_FIELD}    xpath=//input[@name='username']
${PASSWORD_FIELD}    xpath=//input[@name='password']
${SIGN_IN}           xpath=//button[@type='submit']    
${DASHBOARD_LOGO}      xpath=//*[@id="app"]/div[1]/div[1]/header/div[1]/div[1]/span/h6
 

*** Keywords ***
Open Login Page
    ${service}=    Get Chrome Service
    Open Browser    ${URL}    chrome    service=${service}
    sleep           15s
    Maximize Browser Window   

Input Username    
    [Arguments]    ${username}
    sleep          10s
    Input Text     ${USERNAME_FIELD}    ${username}

Input Password    
    [Arguments]   ${password}
    Input Text    ${PASSWORD_FIELD}    ${password}

Click Login Button
    Click element    ${SIGN_IN}
    Wait Until Page Contains Element    ${DASHBOARD_LOGO}    15s

closing all browsers
    Close Browser