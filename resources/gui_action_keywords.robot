*** Settings ***
Library    ../utilities/prompt_for_self_healed_locators.py
Library    ../utilities/LocalLLMClient.py
Library    OperatingSystem
Library    Collections
Library    SeleniumLibrary    screenshot_on_failure=False

***Variables***


***Keywords***
KW Perform Action With Self Healing
    [Arguments]    ${action_keyword}    ${locator}    @{args}

    # First Attempt
    # Checking whether element is found and action is performed successfully with the locator defined in corresponding page or not
    ${status}     Run keyword and return status       ${action_keyword}    ${locator}    @{args}
    Log to console    First attempt with original locator: ${status}

    # If first attempt is successful then it will log the success message in console and if it is not successful then it will get the alternative locator from LLM and perform the action with alternative locator
    IF    '${status}' == 'True'
        Log To Console    Element found and action performed successfully with locator defined in corresponding page (POM).
    ELSE IF    '${status}' == 'False'
        Log To Console    Element not found or action failed with locator defined in corresponding page (POM).
        # Getting page source details so that it can be passed to LLM for getting alternative xpath
        ${page_source}=    Get Source
        log to console    ${page_source}
        ${locator_type}    ${locator_value}=    Split String    ${locator}    =   1
        # Getting locator type so that it can be passed to LLM for getting alternative xpath
        log to console    *** This is LOCATOR TYPE: ${locator_type}
        # Getting locator value so that it can be passed to LLM for getting alternative xpath
        log to console    *** This is LOCATOR VALUE: ${locator_value}
        # Preparing prompt with 'Page source', 'Locator Type', 'Locator' value
        ${resp_self_healed_prompt}=    generate_prompt_for_alternative_self_healed_locators    ${page_source}    ${locator_type}    ${locator_value}
        Log to console    **********************************************************
        log to console    ${resp_self_healed_prompt}
        # Passsing the promt to local LLM and getting the alternative locators as json
        Log to console    **********************************************************
        Log to console    *** Passing the prompt to LLM for getting alternative self healed locators ......
        ${resp_self_healed_locators_from_llm}=    Get LLM Response    ${resp_self_healed_prompt}
        Log to console    **********************************************************
        log to console    Alternative locators suggested by LLM in JSON format: ${resp_self_healed_locators_from_llm}
        Log to console    **********************************************************
        # Deserializing json response with alternative locator values
        ${locator}=    Evaluate    json.loads('''${resp_self_healed_locators_from_llm}''')    json
        # ** Checking how to get value for individual json object parameters and the type as it should be string
        log to console    Deserialized alternative locators suggested by LLM in JSON format: ${locator}
        Log to console    **********************************************************

        # ******************************************

        # Now need to go through these json response and will try with one by one alternative locator suggested by LLM until the element is found and action is performed successfully or the list of alternative locators is exhausted
        FOR      ${alt_locator}    IN
        ...      ${locator['xpath']}
        ...      ${locator['cssSelector']}
        ...      ${locator['id']}
        ...      ${locator['name']}

            ${status}=    Run Keyword And Return Status
            ...    ${action_keyword}    ${alt_locator}    @{args}

            Log To Console    Attempt with alternative locator resulted in status.

            IF    ${status}
                Log to console    **********************************************************
                Log To Console    Element found and action performed successfully with alternative locator: ${alt_locator}
                Log to console    **********************************************************
                
                # Adding this code
                
                # Identifying the locator which is suggested by LLM and worked successsfully.
                ${locator_type}=    Set Variable    ${EMPTY}
                Log to console   Identifying the locator which is suggested by LLM and worked successsfully.

                IF      $alt_locator == $locator["xpath"]
                        ${locator_type}=    Set Variable    xpath
                ELSE IF    $alt_locator == $locator["cssSelector"]
                        ${locator_type}=    Set Variable    cssSelector
                ELSE IF    $alt_locator == $locator["id"]
                        ${locator_type}=    Set Variable    id
                ELSE IF    $alt_locator == $locator["name"]
                        ${locator_type}=    Set Variable    name
                END

                # 🔥 Create dictionary with only working locator
                ${working_locator}=    Create Dictionary    ${locator_type}=${alt_locator}
                Log To Console    Working locator dictionary: ${working_locator}

                ${cache_file}=    Normalize Path
                ...    ${EXECDIR}/utilities/cache_alternative_locator.json

                Log To Console    Cache file path: ${cache_file}

                ${exists}=    Run Keyword And Return Status
                ...    File Should Exist    ${cache_file}

                IF    ${exists}
                    ${content}=    Get File    ${cache_file}
                    ${stripped}=    Strip String    ${content}

                    IF    $stripped == ''
                        ${cache_list}=    Create List
                    ELSE
                        ${status}    ${loaded}=    Run Keyword And Ignore Error
                        ...    Evaluate    __import__('json').loads($content)

                        IF    '${status}' == 'PASS'

                            ${is_list}=    Evaluate    isinstance($loaded, list)

                            IF    ${is_list}
                                ${cache_list}=    Set Variable    ${loaded}
                            ELSE
                                ${cache_list}=    Create List    ${loaded}
                            END

                        ELSE
                            Log To Console    ⚠ Invalid JSON. Resetting cache.
                            ${cache_list}=    Create List
                        END
                    END
                ELSE
                    ${cache_list}=    Create List
                END

                ${size}=    Get Length    ${working_locator}
                IF    ${size} == 0
                    Log To Console    ⚠ Working locator empty. Skipping.
                    RETURN
                END

                ${keys}=    Get Dictionary Keys    ${working_locator}
                ${locator_type}=    Get From List    ${keys}    0
                ${new_value}=    Get From Dictionary    ${working_locator}    ${locator_type}

                Log To Console    Locator Type: ${locator_type}
                Log To Console    Locator Value: ${new_value}

                ${already_exists}=    Set Variable    False

                FOR    ${item}    IN    @{cache_list}

                    ${item_size}=    Get Length    ${item}
                    IF    ${item_size} == 0
                        Continue For Loop
                    END

                    ${item_keys}=    Get Dictionary Keys    ${item}
                    ${item_type}=    Get From List    ${item_keys}    0
                    ${item_value}=    Get From Dictionary    ${item}    ${item_type}

                    IF    $item_type == $locator_type and $item_value == $new_value
                        ${already_exists}=    Set Variable    True
                        Exit For Loop
                    END

                END

                IF    not ${already_exists}
                    Append To List    ${cache_list}    ${working_locator}
                    Log To Console    ✅ Locator added to cache.
                ELSE
                    Log To Console    ⚠ Locator already exists. Skipping append.
                END

                ${updated_json}=    Evaluate
                ...    __import__('json').dumps($cache_list, indent=4)

                Create File    ${cache_file}    ${updated_json}

                Log To Console    ✅ Cache update complete.
                Log To Console    *****************************************************

                # Adding this code
                
                
                
                
                BREAK
            ELSE
                Log To Console    Element not found. Trying next alternative locator...
                Log to console    **********************************************************
            END

        END

    END    


KW Input Text with self healing
    [Arguments]     ${element}   ${value}
    KW Perform Action With Self Healing     Input Text      ${element}      ${value}

KW Click Button with self healing
    [Arguments]     ${element}
    KW Perform Action With Self Healing     Click Button     ${element}    

