*** Settings ***
Resource    ../resources/login_page.robot
Resource    ../resources/dashboard_page.robot
Library     SeleniumLibrary
Library    ../utilities/LocalLLMClient.py
Library    ../utilities/prompt_for_self_healed_locators.py
#Library    SeleniumLibrary    screenshot_on_failure=False
Library    SeleniumLibrary    run_on_failure=Nothing

*** Variables ***
${USERNAME}     Admin
${PASSWORD}     admin123

*** Test Cases ***
Valid Login Test
    [Tags]        test1
    [Documentation]    Test valid login on sauce-demo Shopify app
    Kw Open Login Page    
    Kw Input Username      ${USERNAME}
    Kw Input Password      ${PASSWORD}
    Kw Click Login Button
    Kw Verify Successful Login
    Kw Close All Browsers

Test_Local_LLM
    [Tags]    test2
    ${resp}=    Get LLM Response    Write simple selenium code using robot framework on google.com   
    Log to console   ${resp}

Test_alternative_locator_by_llm
    [Tags]        test3
    [Documentation]   Test to get alternative locator from LLM
    ...    in order to get alternative locator for login button on sauce-demo Shopify app we need to
    ...   pass 'page source, locator type and locator value' to LLM
    # Opening login page
    KW Open Login Page 
    # Getting page source details so that it can be passed to LLM for getting alternative xpath
    ${LOGIN_Page_Source}=    kW Get Page Source
    log to console    ${LOGIN_Page_Source}
    ${USERNAME_FIELD_LOCATOR_TYPE}  ${USERNAME_FIELD_LOCATOR_VALUE}=    Kw Get Locator Details    ${USERNAME_FIELD}
    # Getting locator type so that it can be passed to LLM for getting alternative xpath
    log to console    *** This is Username LOCATOR TYPE: ${USERNAME_FIELD_LOCATOR_TYPE}
    # Getting locator value so that it can be passed to LLM for getting alternative xpath
    log to console    *** This is Username LOCATOR VALUE: ${USERNAME_FIELD_LOCATOR_VALUE}
    # Preparing prompt with 'Page source', 'Locator Type', 'Locator' value
    ${resp_self_healed_prompt}=    generate_alternative_self_healed_locators_keyword    ${LOGIN_Page_Source}    ${USERNAME_FIELD_LOCATOR_TYPE}    ${USERNAME_FIELD_LOCATOR_VALUE}
    log to console    ${resp_self_healed_prompt}
    # Passsing the promt to local LLM and getting the alternative locators as json
    ${resp_self_healed_locators_from_llm}=    Get LLM Response    ${resp_self_healed_prompt}
    log to console    ${resp_self_healed_locators_from_llm}
    # Deserializing json response with alternative locator values
    ${locator}=    Evaluate    json.loads('''${resp_self_healed_locators_from_llm}''')    json
    # ** Checking how to get value for individual json object parameters and the type as it should be string
    log to console    ${locator}
    # Log to console    ${locator["xpath"]}
    # ${locator_value}    set Variable    ${locator["xpath"]}
    # ${type}=     Evaluate    type($locator_value).__name__
    # Log to console    ${type}

Test_alternative_locator_by_llm_004
    [Tags]      test4
    # Opening login page
    KW Open Login Page 
    Kw input username  Admin
    Kw input password  admin123
    Kw Click Login Button
    Kw Verify Dashboard logo is visible
