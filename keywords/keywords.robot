*** Settings ***
Library            RPA.Robocorp.Vault
Library            RPA.Browser.Playwright
Library            RPA.Archive
Library            RPA.Dialogs
Library            RPA.PDF
Library            RPA.Tables
Library            Dialogs
Library            String
Library            DateTime
Library            OperatingSystem
Library            Collections
Resource           variables.robot


*** Keywords ***
User form
    Add heading           Type URL to download orders file
    Add text input        url    label=Url  placeholder=https://robotsparebinindustries.com/orders.csv
    ${Result}=            Run dialog
    Set Suite Variable    ${USER_PROVIDED_URL}  ${Result.url}
    Log To Console        ${USER_PROVIDED_URL}
    IF     '${USER_PROVIDED_URL}'=='${EMPTY}'
        Pass Execution    Ei tiedostoa
    END

Open orders website
    New Context        acceptDownloads=${True}
    Wait Until Keyword Succeeds    3x    0.5 sec    New page       https://robotsparebinindustries.com/#/robot-order

Download CSV
    [Documentation]  This uses default temp location for download.  
    ${download_promise}=    Promise To Wait For Download    #${FILEPATH}${/}orders.csv
    ${file_object}=         Download            ${USER_PROVIDED_URL}
    Wait For                ${download_promise}
    Set Suite Variable      ${FILE}             ${file_object.saveAs}


Read data from CSV
    ${orders}=             Read table from CSV     ${FILE}
    Set Suite Variable     ${orders}               ${orders}
    [Return]    ${orders}


Fill form and send order
    [Arguments]    ${row}
    Reload    
    Handle popup
    Read info
    ${new_row}=    Select right item from info         ${row} 
    Fill from   ${new_row}    ${row}
    Preview the robot
    Submit the order

Handle popup
    #Wait For Elements State     //button[contains(text(),'I guess so..')]         state=visible   timeout=5s
    Click                       //button[contains(text(),'I guess so..')]
    Wait For Elements State     //button[contains(text(),'I guess so..')]         state=hidden    timeout=5s


Read info
    #Wait For Elements State       //button[contains(text(),'Show model info')]    state=visible
    Click                         //button[contains(text(),'Show model info')]
    Wait For Elements State       //table[@id='model-info']     state=visible
    ${INFO_TABLE}=                Get Text            //table[@id='model-info'] 
    @{INFO_TABLE}=                Split String        ${INFO_TABLE}    \n
    Set Suite Variable            ${INFO_TABLE}       ${INFO_TABLE}
    

Fill from
    [Arguments]    ${items}    ${org_items}
    Choose item from dropdown           //select[@id='head']        ${items}[0]
    Choose item from radiobutton        //label[contains(text(),'${items}[1]') and child::input[@type='radio']] 
    Write text                          //input[@class='form-control' and @type='number' and contains(@placeholder,'Enter the part number for the legs')]    ${org_items}[Legs]
    Write text                          //input[@class='form-control' and @type='text' and @id='address']        ${items}[3]
  

Select right item from info
    [Documentation]  #Some unnecessary extra fun when selecting items.   
    [Arguments]    ${items}
    FOR    ${row}    IN    @{INFO_TABLE}
        ${temp}=    Set Variable    ${items}[Head]
        IF    '${row[-len(str(${temp})):]}'=='${temp}'    #IF  '${row[-1:].find('${temp}')>-1}'=='True'
            ${head}=    Set Variable     ${row.replace('\t${temp}',' head')}
            Log To Console    ${head}
        END
        ${temp2}=    Set Variable    ${items}[Body]
        IF    '${row[-len(str(${temp2})):]}'=='${temp2}'    #IF  '${row[-1:].find('${temp2}')>-1}'=='True'
            ${body}=    Set Variable     ${row.replace('\t${temp2}',' body')}
            Log To Console    ${body}
        END
        ${temp3}=    Set Variable    ${items}[Legs]
        IF    '${row[-len(str(${temp3})):]}'=='${temp3}'    #IF  '${row[-1:].find('${temp3}')>-1}'=='True'
            ${legs}=    Set Variable     ${row.replace('\t${temp3}',' legs')}
            Log To Console    ${legs}
        END 
        ${address}=    Set Variable    ${items}[Address]
    END
    ${new_row}=    Create List	${head}	${body}	${legs}	${address}
    [Return]      ${new_row}


Choose item from dropdown
    [Arguments]    ${locator}    ${item}
    #Wait For Elements State     //select[@id='head']   state=visible    timeout=5s
    Select Options By    //select[@id='head']    text    ${item}
    ${selected}=  Get Selected Options    //select[@id='head']
    IF    '${selected}'!='${item}'
        Fail
    END


Choose item from radiobutton
    [Arguments]    ${locator}
    #Wait For Elements State     ${locator}   state=visible    timeout=5s
    Check Checkbox     ${locator}
    ${selected}=  Get Element States    ${locator}
    IF    '${selected}[5]'!='checked'
        Fail
    END


Write text
    [Arguments]    ${locator}    ${item}
    #Wait For Elements State     ${locator}   state=visible    timeout=5s
    Fill Text     ${locator}        ${item}
    ${value}=  Get Text    ${locator}
    IF    '${value}'!='${item}'
        Fail
    END


Order another robot
    General Click        //button[@id='order-another']      //button[contains(text(),'I guess so..')]


Submit the order
    General Click        //button[@id='order']              //div[@id='receipt' and @class='alert alert-success']


Preview the robot
    General Click        //button[@id='preview']            //div[@id='robot-preview-image']


General Click
    [Arguments]    ${locator}     ${locator2}
    #Wait For Elements State     ${locator}    state=visible    timeout=5s
    Click    ${locator}
    Wait For Elements State     ${locator2}   state=visible    timeout=5s


Add recipient to PDF report
    [Arguments]    ${id}
    ${today_time}=       Get Current Date         time_zone=local  increment=0  result_format=%Y-%m-%d_%H%M%S  exclude_millis=False 
    ${data}=             Get Property             //div[@id='receipt' and @class='alert alert-success']    outerHTML
    HTML to PDF          ${data}                  ${OUTPUTDIR}${/}Reports${/}Temp${/}recipients_${today_time}_${id}.pdf
    ${screenshot}=       Take Screenshot          filename=${/}Reports${/}temp${/}recipient_${today_time}_${id}    selector=//div[@id='robot-preview-image']
    ${files}=            Create List              ${screenshot}
    Add Files To Pdf     ${files}                 ${OUTPUTDIR}${/}Reports${/}Temp${/}recipients_${today_time}_${id}.pdf        append=True  


Create ZIP file
    ${today_time}=              Get Current Date         time_zone=local  increment=0  result_format=%Y-%m-%d_%H%M%S  exclude_millis=False
    Archive Folder With Zip     ${OUTPUTDIR}${/}Reports${/}Temp    ${OUTPUTDIR}${/}Reports${/}Reports_ ${today_time}.zip


Append to error file
    [Arguments]    ${items}
    ${today}=            Get Current Date         time_zone=local  increment=0  result_format=%Y-%m-%d  exclude_millis=False
    ${today_time}=       Get Current Date         time_zone=local  increment=0  result_format=%Y-%m-%d_%H%M%S  exclude_millis=False
    Append To File       ${OUTPUTDIR}${/}Reports${/}Error_rows_${today}.txt    Order number:${items}[Order number] Head:${items}[Head] Body:${items}[Body] Legs:${items}[Legs] Address:${items}[Address] ${today_time}\n    encoding=UTF-8


Clean Temp Folder    
    ${temp_files}=    List Directory    ${OUTPUTDIR}${/}Reports${/}Temp
    FOR    ${file}    IN    @{temp_files}
        Remove File              ${OUTPUTDIR}${/}Reports${/}Temp${/}${file}
        File Should Not Exist    ${OUTPUTDIR}${/}Reports${/}Temp${/}${file}
    END

Spill the secrets
    ${secret}=    Get Secret    secrets
    Log To Console    ${secret}[secret1]
    Log To Console    ${secret}[secret2]

