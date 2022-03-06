*** Settings ***
Documentation    Certificate robot using Playwright/RF Browserlibrary. 
Resource          keywords.robot
Resource          variables.robot


*** Tasks ***
Ordering robots
    [Documentation]    Using CSV to order robot parts and packing receipts to zip -file 
    [Tags]  Robocorp2
    User form
    Open orders website
    Download CSV
    ${orders}=    Read data from CSV
    FOR    ${row}    IN    @{orders}
        Log To Console    ${row} 
        ${SUCCESS}=    Run Keyword And Return Status    Wait Until Keyword Succeeds    3x    0.5 sec      Fill form and send order       ${row}
        IF    ${SUCCESS} == ${False}
            Append to error file    ${row}
            Continue For Loop
        END
        Add recipient to PDF report    ${row}[Order number]
        Order another robot
    END
    Create ZIP file
    Clean Temp Folder
    Spill the secrets    
    Log To Console    Bzzzzz

[Teardown]  Log To Console    Shutting down...