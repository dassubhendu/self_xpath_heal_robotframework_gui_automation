*** Settings ***
Resource    ../resources/login_page.robot
Library     SeleniumLibrary
Library    ../utilities/LocalLLMKeywords.py

*** Variables ***
${USERNAME}     Admin
${PASSWORD}     admin123

*** Test Cases ***
Valid Login Test
    [Documentation]    Test valid login on sauce-demo Shopify app
    Open Login Page    
    Input Username      ${USERNAME}
    Input Password      ${PASSWORD}
    Click Login Button
    # Add verification if needed, e.g., check logout link
    Close Browser

Test_Local_LLM
    [Tags]        test
    #${resp}=    Get LLM Response    Why is the sky blue?
    ${resp}=    Get LLM Response    Write simple selenium code using robot framework on google.com
    Log    ${resp}
        
