*** Settings ***
Library    ../utilities/prompt_for_self_healed_locators.py
Library    ../utilities/LocalLLMClient.py
Library    ../utilities/CloudLLMClient.py
Library    OperatingSystem
Library    Collections
Library    SeleniumLibrary    screenshot_on_failure=False

***Variables***


***Keywords***

KW Perform Action With Self Healing
    [Arguments]    ${action_keyword}    ${locator}    @{args}

    Log To Console    ${EMPTY}
    Log To Console    ╔══════════════════════════════════════════════════════════════╗
    Log To Console    ║ 🚀 SELF HEALING ACTION EXECUTION STARTED ║
    Log To Console    ╚══════════════════════════════════════════════════════════════╝
    Log To Console    🔹 Action Keyword : ${action_keyword}
    Log To Console    🔹 Original Locator: ${locator}

    ${cache_file}=    Normalize Path
    ...    ${EXECDIR}/utilities/cache_alternative_locator.json

    ${original_locator_string}=    Set Variable    ${locator}

    Log To Console    📁 Cache file location: ${cache_file}

    # =====================================================
    # STEP 1 - TRY ORIGINAL LOCATOR (POM)
    # =====================================================

    Log To Console    ┌──────────────────────────────────────────────────────────────┐
    Log To Console    │ STEP 1: ATTEMPT USING ORIGINAL LOCATOR FROM POM              │
    Log To Console    └──────────────────────────────────────────────────────────────┘
    Log To Console    🔍 Trying original locator from Page Object Model...

    ${status}=    Run Keyword And Return Status
    ...    ${action_keyword}    ${locator}    @{args}

    Log To Console    ----------------------------------------------------------
    Log To Console    🧪 Attempt Result: ${status}
    Log To Console    📌 Locator Used : ${locator}
    Log To Console    ----------------------------------------------------------

    IF    ${status}
        Log To Console    ✅ SUCCESS: Element located using original POM locator.
        Log To Console    🎯 Action executed successfully.
        Log To Console    ══════════════════════════════════════════════════════
        Log To Console    🏁 EXECUTION FINISHED (NO HEALING REQUIRED)
        Log To Console    ══════════════════════════════════════════════════════
        RETURN
    END

    Log To Console    ❌ FAILED: Element not found using POM locator.
    Log To Console    🔄 Moving to next recovery strategy...

    # =====================================================
    # STEP 2 - TRY CACHE
    # =====================================================

    Log To Console    ┌──────────────────────────────────────────────────────────────┐
    Log To Console    │ STEP 2: ATTEMPT USING CACHED STABLE LOCATOR                  │
    Log To Console    └──────────────────────────────────────────────────────────────┘
    Log To Console    🔎 Checking if cached locator exists for this element...

    ${cache_success}=    Set Variable    False

    ${cache_exists}=    Run Keyword And Return Status
    ...    File Should Exist    ${cache_file}

    Log To Console    📂 Cache file exists: ${cache_exists}

    IF    ${cache_exists}

        Log To Console    📖 Reading cache file...

        ${content}=    Get File    ${cache_file}
        ${stripped}=    Strip String    ${content}

        IF    ${stripped}

            Log To Console    📦 Cache content detected. Parsing JSON...

            ${status_json}    ${cache_dict}=    Run Keyword And Ignore Error
            ...    Evaluate    __import__('json').loads($content)

            IF    $status_json == 'PASS' and isinstance($cache_dict, dict)

                Log To Console    🧠 Cache JSON successfully parsed.

                ${key_exists}=    Run Keyword And Return Status
                ...    Dictionary Should Contain Key
                ...    ${cache_dict}    ${original_locator_string}

                Log To Console    🔑 Cache entry found for locator: ${key_exists}

                IF    ${key_exists}

                    ${entry}=    Get From Dictionary
                    ...    ${cache_dict}    ${original_locator_string}

                    ${cached_locator}=    Get From Dictionary
                    ...    ${entry}    current_stable_locator

                    Log To Console    🎯 Cached stable locator identified:
                    Log To Console    👉 ${cached_locator}

                    Log To Console    🧪 Attempting action using cached locator...

                    ${status}=    Run Keyword And Return Status
                    ...    ${action_keyword}    ${cached_locator}    @{args}

                    Log To Console    📊 Result using cached locator: ${status}

                    IF    ${status}
                        ${cache_success}=    Set Variable    True
                        Log To Console    ✅ SUCCESS: Element found using cached stable locator.
                        Log To Console    📌 Cached Locator: ${cached_locator}
                        Log To Console    ══════════════════════════════════════════════════════
                        Log To Console    🏁 EXECUTION FINISHED (CACHE RECOVERY SUCCESS)
                        Log To Console    ══════════════════════════════════════════════════════
                        RETURN
                    END

                    Log To Console    ❌ Cached locator attempt failed.

                END
            END
        END
    END

    Log To Console    ⚠️ No usable cached locator found or cache attempt failed.
    Log To Console    🔄 Escalating to LLM-based self healing...

    # =====================================================
    # STEP 3 - LLM SELF HEALING
    # =====================================================

    Log To Console    ┌──────────────────────────────────────────────────────────────┐
    Log To Console    │ STEP 3: LLM POWERED SELF-HEALING                             │
    Log To Console    └──────────────────────────────────────────────────────────────┘

    Log To Console    🤖 Initiating LLM-assisted locator recovery...

    Log to console   📄 Fetching page source for LLM analysis...

    ${page_source}=    Get Source

    Log to console   🔎 Extracting locator type and value...

    ${locator_type}    ${locator_value}=    Split String
    ...    ${original_locator_string}    =    1

    Log To Console    Locator Type : ${locator_type}
    Log To Console    Locator Value: ${locator_value}

    Log To Console    🧠 Generating prompt for LLM...

    ${resp_self_healed_prompt}=    generate_prompt_for_alternative_self_healed_locators
    ...    ${page_source}
    ...    ${locator_type}
    ...    ${locator_value}

    Log To Console    ----------------------------------------------------------
    Log To Console    📜 Generated LLM Prompt
    Log To Console    ----------------------------------------------------------
    Log to console    ${resp_self_healed_prompt}

    Log To Console    🚀 Sending prompt to LLM service...

    ${resp_self_healed_locators_from_llm}=    Get LLM Response Cloud
    ...    ${resp_self_healed_prompt}

    Log To Console    📦 LLM Response Received
    Log To Console    Alternative locators JSON:
    Log To Console    ${resp_self_healed_locators_from_llm}

    ${locator_json}=    Evaluate
    ...    json.loads('''${resp_self_healed_locators_from_llm}''')    json

    ${llm_success}=    Set Variable    False

    Log To Console    🔁 Starting alternative locator attempts suggested by LLM...

    FOR    ${alt_locator}    IN
    ...    ${locator_json['xpath']}
    ...    ${locator_json['cssSelector']}
    ...    ${locator_json['id']}
    ...    ${locator_json['name']}

        Log To Console    ------------------------------------------------------
        Log To Console    🧪 Trying Alternative Locator
        Log To Console    👉 ${alt_locator}

        ${status}=    Run Keyword And Return Status
        ...    ${action_keyword}    ${alt_locator}    @{args}

        Log To Console    📊 Attempt Result: ${status}

        IF    ${status}

            ${llm_success}=    Set Variable    True

            Log To Console    ✅ SUCCESS: Element located with alternative locator.
            Log To Console    🎯 Working Locator: ${alt_locator}

            # ================= CACHE UPDATE =================
            Log to console    ┌──────────────────────────────────────────────────────┐
            Log to console    │ CACHE UPDATE PROCESS                                 │
            Log to console    └──────────────────────────────────────────────────────┘

            Log to console    💾 Saving new stable locator to cache...

            ${today}=    Evaluate
            ...    __import__('datetime').datetime.now().strftime('%Y-%m-%d')

            ${exists}=    Run Keyword And Return Status
            ...    File Should Exist    ${cache_file}

            IF    ${exists}
                ${content}=    Get File    ${cache_file}
                ${status_json}    ${cache_dict}=    Run Keyword And Ignore Error
                ...    Evaluate    __import__('json').loads($content)

                IF    not $cache_dict
                    ${cache_dict}=    Create Dictionary
                END
            ELSE
                ${cache_dict}=    Create Dictionary
            END

            ${history_list}=    Create List    ${alt_locator}

            ${new_entry}=    Create Dictionary
            ...    original_locator=${original_locator_string}
            ...    current_stable_locator=${alt_locator}
            ...    locator_history=${history_list}
            ...    heal_count=1
            ...    last_healed_on=${today}

            Set To Dictionary
            ...    ${cache_dict}
            ...    ${original_locator_string}=${new_entry}

            ${updated_json}=    Evaluate
            ...    __import__('json').dumps($cache_dict, indent=4)

            Remove File    ${cache_file}
            Create File    ${cache_file}    ${updated_json}

            Log To Console    ✅ Cache update complete.
            Log To Console    📁 Stable locator stored for future executions.

            Log To Console    ══════════════════════════════════════════════════════
            Log To Console    🏁 EXECUTION FINISHED (LLM HEALING SUCCESS)
            Log To Console    ══════════════════════════════════════════════════════

            BREAK
        END

        Log To Console    ❌ Locator failed. Trying next candidate...

    END

    # =====================================================
    # EXPLICIT FAILURE CHECK
    # =====================================================

    IF    not ${llm_success}
        Log To Console    ╔══════════════════════════════════════════════════════════╗
        Log To Console    ║                  ❌ SELF HEALING FAILED                   ║
        Log To Console    ╠══════════════════════════════════════════════════════════╣
        Log To Console    ║ Original Locator  → FAILED                               ║
        Log To Console    ║ Cached Locator    → FAILED                               ║
        Log To Console    ║ LLM Alternatives  → FAILED                               ║
        Log To Console    ╚══════════════════════════════════════════════════════════╝

        Fail    Self-healing failed. Original locator, cache and all LLM locators did not work.
    END

# KW Perform Action With Self Healing
#     [Arguments]    ${action_keyword}    ${locator}    @{args}

#     ${cache_file}=    Normalize Path
#     ...    ${EXECDIR}/utilities/cache_alternative_locator.json

#     ${original_locator_string}=    Set Variable    ${locator}

#     # =====================================================
#     # STEP 1 - TRY ORIGINAL LOCATOR (POM)
#     # =====================================================

#     ${status}=    Run Keyword And Return Status
#     ...    ${action_keyword}    ${locator}    @{args}
#     Log To Console    ==========================================================
#     Log To Console    **********************************************************
#     Log To Console    First attempt with original locator: ${status} with locator: ${locator}

#     IF    ${status}
#         Log To Console    Element found and action performed successfully with locator defined in corresponding page (POM).
#         RETURN
#     END
#     Log To Console    Element not found or action failed with locator defined in corresponding page (POM).

#     # =====================================================
#     # STEP 2 - TRY CACHE
#     # =====================================================

#     Log To Console    **********************************************************
#     Log To Console    Attempting to find element using cached stable locator if available...

#     ${cache_success}=    Set Variable    False

#     ${cache_exists}=    Run Keyword And Return Status
#     ...    File Should Exist    ${cache_file}

#     IF    ${cache_exists}

#         ${content}=    Get File    ${cache_file}
#         ${stripped}=    Strip String    ${content}

#         IF    ${stripped}

#             ${status_json}    ${cache_dict}=    Run Keyword And Ignore Error
#             ...    Evaluate    __import__('json').loads($content)

#             IF    $status_json == 'PASS' and isinstance($cache_dict, dict)

#                 ${key_exists}=    Run Keyword And Return Status
#                 ...    Dictionary Should Contain Key
#                 ...    ${cache_dict}    ${original_locator_string}

#                 IF    ${key_exists}

#                     ${entry}=    Get From Dictionary
#                     ...    ${cache_dict}    ${original_locator_string}

#                     ${cached_locator}=    Get From Dictionary
#                     ...    ${entry}    current_stable_locator

#                     Log To Console    Trying cached locator: ${cached_locator}

#                     ${status}=    Run Keyword And Return Status
#                     ...    ${action_keyword}    ${cached_locator}    @{args}
#                     Log To Console    Attempt with cached locator resulted in status: ${status}

#                     IF    ${status}
#                         ${cache_success}=    Set Variable    True
#                         Log To Console    Element found using cached stable locator.
#                         Log To Console    Cached locator: ${cached_locator}
#                         RETURN
#                     END

#                 END
#             END
#         END
#     END
#     Log To Console    Cached locator not found or failed. Moving to LLM healing.

#     # =====================================================
#     # STEP 3 - LLM SELF HEALING
#     # =====================================================

#     Log to console    **********************************************************
#     Log To Console    Attempting self-healing with LLM-suggested alternative locators

#     Log to console   Getting page source for generating prompt for LLM...

#     ${page_source}=    Get Source

#     Log to console   Getting Locator type and value for generating prompt for LLM...

#     ${locator_type}    ${locator_value}=    Split String
#     ...    ${original_locator_string}    =    1

#     ${resp_self_healed_prompt}=    generate_prompt_for_alternative_self_healed_locators
#     ...    ${page_source}
#     ...    ${locator_type}
#     ...    ${locator_value}

#     Log To Console    Prompt has been designed for LLM: 
#     Log to console    ${resp_self_healed_prompt}

#     Log To Console    *** Passing the prompt to LLM for getting alternative self healed locators ......

#     ${resp_self_healed_locators_from_llm}=    Get LLM Response Cloud
#     ...    ${resp_self_healed_prompt}

#     Log To Console    Alternative locators suggested by LLM in JSON format: ${resp_self_healed_locators_from_llm}

#     ${locator_json}=    Evaluate
#     ...    json.loads('''${resp_self_healed_locators_from_llm}''')    json

#     ${llm_success}=    Set Variable    False

#     FOR    ${alt_locator}    IN
#     ...    ${locator_json['xpath']}
#     ...    ${locator_json['cssSelector']}
#     ...    ${locator_json['id']}
#     ...    ${locator_json['name']}

#         ${status}=    Run Keyword And Return Status
#         ...    ${action_keyword}    ${alt_locator}    @{args}

#         Log To Console    Attempt with alternative locator resulted in status: ${status}

#         IF    ${status}

#             ${llm_success}=    Set Variable    True

#             Log To Console    Element found and action performed successfully with alternative locator: ${alt_locator}

#             # ================= CACHE UPDATE =================
#             Log to console    **********************************************************
#             Log to console    Updating cache with new stable locator...
#             ${today}=    Evaluate
#             ...    __import__('datetime').datetime.now().strftime('%Y-%m-%d')

#             ${exists}=    Run Keyword And Return Status
#             ...    File Should Exist    ${cache_file}

#             IF    ${exists}
#                 ${content}=    Get File    ${cache_file}
#                 ${status_json}    ${cache_dict}=    Run Keyword And Ignore Error
#                 ...    Evaluate    __import__('json').loads($content)

#                 IF    not $cache_dict
#                     ${cache_dict}=    Create Dictionary
#                 END
#             ELSE
#                 ${cache_dict}=    Create Dictionary
#             END

#             ${history_list}=    Create List    ${alt_locator}

#             ${new_entry}=    Create Dictionary
#             ...    original_locator=${original_locator_string}
#             ...    current_stable_locator=${alt_locator}
#             ...    locator_history=${history_list}
#             ...    heal_count=1
#             ...    last_healed_on=${today}

#             Set To Dictionary
#             ...    ${cache_dict}
#             ...    ${original_locator_string}=${new_entry}

#             ${updated_json}=    Evaluate
#             ...    __import__('json').dumps($cache_dict, indent=4)

#             Remove File    ${cache_file}
#             Create File    ${cache_file}    ${updated_json}

#             Log To Console    ✅ Cache update complete.

#             BREAK
#         END

#     END

#     # =====================================================
#     # EXPLICIT FAILURE CHECK
#     # =====================================================

#     IF    not ${llm_success}
#         Log To Console    **********************************************************
#         Log To Console    ❌ All alternative locators suggested by LLM failed.
#         Log To Console    **********************************************************
#         Fail    Self-healing failed. Original locator, cache and all LLM locators did not work.
#     END

# KW Perform Action With Self Healing
#     [Arguments]    ${action_keyword}    ${locator}    @{args}

#     # First Attempt
#     ${status}     Run keyword and return status       ${action_keyword}    ${locator}    @{args}
#     Log to console    First attempt with original locator: ${status} with locator: ${locator}

#     IF    '${status}' == 'True'
#         Log To Console    Element found and action performed successfully with locator defined in corresponding page (POM).

#     ELSE IF    '${status}' == 'False'
#         Log To Console    Element not found or action failed with locator defined in corresponding page (POM).

#         # ✅ PRESERVE ORIGINAL LOCATOR STRING (IMPORTANT FIX)
#         ${original_locator_string}=    Set Variable    ${locator}

#         ${page_source}=    Get Source
#         Log to console    ${page_source}

#         ${locator_type}    ${locator_value}=    Split String    ${locator}    =   1
#         Log to console    *** This is LOCATOR TYPE: ${locator_type}
#         Log to console    *** This is LOCATOR VALUE: ${locator_value}

#         ${resp_self_healed_prompt}=    generate_prompt_for_alternative_self_healed_locators
#         ...    ${page_source}
#         ...    ${locator_type}
#         ...    ${locator_value}

#         Log to console    **********************************************************
#         Log to console    ${resp_self_healed_prompt}
#         Log to console    **********************************************************
#         Log to console    *** Passing the prompt to LLM for getting alternative self healed locators ......

#         ${resp_self_healed_locators_from_llm}=    Get LLM Response Cloud    ${resp_self_healed_prompt}

#         Log to console    **********************************************************
#         Log to console    Alternative locators suggested by LLM in JSON format: ${resp_self_healed_locators_from_llm}
#         Log to console    **********************************************************

#         # ⚠ Overwriting ${locator} intentionally with LLM JSON
#         ${locator}=    Evaluate    json.loads('''${resp_self_healed_locators_from_llm}''')    json
#         Log to console    Deserialized alternative locators suggested by LLM in JSON format: ${locator}
#         Log to console    **********************************************************

#         FOR    ${alt_locator}    IN
#         ...    ${locator['xpath']}
#         ...    ${locator['cssSelector']}
#         ...    ${locator['id']}
#         ...    ${locator['name']}

#             ${status}=    Run Keyword And Return Status
#             ...    ${action_keyword}    ${alt_locator}    @{args}

#             Log To Console    Attempt with alternative locator resulted in status: ${status}

#             IF    ${status}

#                 Log to console    **********************************************************
#                 Log To Console    Element found and action performed successfully with alternative locator: ${alt_locator}
#                 Log to console    **********************************************************

#                 ${locator_type}=    Set Variable    ${EMPTY}

#                 IF      $alt_locator == $locator["xpath"]
#                         ${locator_type}=    Set Variable    xpath
#                 ELSE IF    $alt_locator == $locator["cssSelector"]
#                         ${locator_type}=    Set Variable    cssSelector
#                 ELSE IF    $alt_locator == $locator["id"]
#                         ${locator_type}=    Set Variable    id
#                 ELSE IF    $alt_locator == $locator["name"]
#                         ${locator_type}=    Set Variable    name
#                 END

#                 ${working_locator}=    Create Dictionary    ${locator_type}=${alt_locator}
#                 Log To Console    Working locator dictionary: ${working_locator}

#                 ${cache_file}=    Normalize Path
#                 ...    ${EXECDIR}/utilities/cache_alternative_locator.json

#                 ${keys}=    Get Dictionary Keys    ${working_locator}
#                 ${size}=    Get Length    ${keys}

#                 IF    ${size} == 0
#                     Log To Console    ⚠ Working locator empty. Skipping.
#                     BREAK
#                 END

#                 ${locator_type}=    Get From List    ${keys}    0
#                 ${new_value}=    Get From Dictionary    ${working_locator}    ${locator_type}

#                 IF    not $new_value or $new_value == 'None'
#                     Log To Console    ⚠ Locator value empty. Skipping.
#                     BREAK
#                 END

#                 # =====================================================
#                 # ✅ UPDATED CACHE STRUCTURE WITH SAFE ORIGINAL STRING
#                 # =====================================================

#                 ${original_key}=    Set Variable    ${original_locator_string}
#                 ${today}=    Evaluate    __import__('datetime').datetime.now().strftime('%Y-%m-%d')
#                 ${full_original}=    Set Variable    ${original_locator_string}
#                 ${full_stable}=      Set Variable    ${locator_type}=${new_value}

#                 ${exists}=    Run Keyword And Return Status
#                 ...    File Should Exist    ${cache_file}

#                 IF    ${exists}

#                     ${content}=    Get File    ${cache_file}
#                     ${stripped}=    Strip String    ${content}

#                     IF    not $stripped
#                         ${cache_dict}=    Create Dictionary
#                     ELSE
#                         ${status_json}    ${loaded}=    Run Keyword And Ignore Error
#                         ...    Evaluate    __import__('json').loads($content)

#                         IF    $status_json == 'PASS' and isinstance($loaded, dict)
#                             ${cache_dict}=    Set Variable    ${loaded}
#                         ELSE
#                             ${cache_dict}=    Create Dictionary
#                         END
#                     END

#                 ELSE
#                     ${cache_dict}=    Create Dictionary
#                 END

#                 ${key_exists}=    Run Keyword And Return Status
#                 ...    Dictionary Should Contain Key    ${cache_dict}    ${original_key}

#                 IF    ${key_exists}

#                     ${entry}=    Get From Dictionary    ${cache_dict}    ${original_key}

#                     ${heal_count}=    Evaluate    int($entry.get("heal_count", 0)) + 1
#                     Set To Dictionary    ${entry}    current_stable_locator=${full_stable}
#                     Set To Dictionary    ${entry}    heal_count=${heal_count}
#                     Set To Dictionary    ${entry}    last_healed_on=${today}

#                     ${history}=    Get From Dictionary    ${entry}    locator_history
#                     ${already}=    Evaluate    $full_stable in $history

#                     IF    not ${already}
#                         Append To List    ${history}    ${full_stable}
#                     END

#                 ELSE

#                     ${history_list}=    Create List    ${full_stable}

#                     ${new_entry}=    Create Dictionary
#                     ...    original_locator=${full_original}
#                     ...    current_stable_locator=${full_stable}
#                     ...    locator_history=${history_list}
#                     ...    heal_count=1
#                     ...    last_healed_on=${today}

#                     Set To Dictionary    ${cache_dict}
#                     ...    ${original_key}=${new_entry}

#                 END

#                 ${updated_json}=    Evaluate
#                 ...    __import__('json').dumps($cache_dict, indent=4)

#                 Remove File    ${cache_file}
#                 Create File    ${cache_file}    ${updated_json}

#                 Log To Console    ✅ Cache update complete.
#                 BREAK

#             ELSE
#                 Log To Console    Element not found. Trying next alternative locator...
#             END

#         END

#         IF    not ${status}
#             Log To Console    ❌ All alternative locators suggested by LLM failed.
#             Fail    Self-healing failed. Original locator and all LLM-suggested locators did not work.
#         END

#     END


KW Input Text with self healing
    [Arguments]     ${element}   ${value}
    KW Perform Action With Self Healing     Input Text      ${element}      ${value}

KW Click Button with self healing
    [Arguments]     ${element}
    KW Perform Action With Self Healing     Click Button     ${element}    


KW Element should be visible with self healing
    [Arguments]     ${element}
    KW Perform Action With Self Healing     Element Should Be Visible     ${element}    

