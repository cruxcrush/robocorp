*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Variables ***
${URL}                      https://robotsparebinindustries.com/#/robot-order
${ORDERS_FILE_PATH}         orders.csv
${TEMP_FILES_DIRECTORY}     ${CURDIR}${/}temp


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Set up directories
    Open the robot order website
    Download orders file
    ${dtOrders}    Get orders
    FOR    ${row}    IN    @{dtOrders}
        Log    ${row}
        Close annoying modal
        Fill the form    ${row}
        Preview robot
        Mute Run On Failure    Submit order
        Wait Until Keyword Succeeds    3 minute    0.5s    Submit order
        ${pdf}    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Delete unecessary images    ${screenshot}
        Next order
    END
    Create a ZIP file of receipt PDF files
    Delete archivied folder

    Log    Done.


*** Keywords ***
Set up directories
    Create Directory    ${TEMP_FILES_DIRECTORY}    exist_ok=True
    Create Directory    ${OUTPUT_DIR}    exist_ok=True

Open the robot order website
    Open Available Browser    ${URL}

Download orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get orders
    ${dtOrders}    Read table from CSV    ${ORDERS_FILE_PATH}
    RETURN    ${dtOrders}

Close annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview robot
    Click Button    preview

Submit order
    Mute Run On Failure    Wait Until Page Contains Element
    Click Button    order
    Wait Until Page Contains Element    id:receipt

Store the receipt as a PDF file
    [Arguments]    ${orderNumber}
    Log    ${orderNumber}
    ${receipt_html}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${TEMP_FILES_DIRECTORY}${/}${orderNumber}.pdf
    RETURN    ${TEMP_FILES_DIRECTORY}${/}${orderNumber}.pdf

Take a screenshot of the robot
    [Arguments]    ${orderNumber}
    ${screenshot}    Screenshot    robot-preview-image    ${TEMP_FILES_DIRECTORY}${/}${orderNumber}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    #Close Pdf    ${pdf}

Delete unecessary images
    [Arguments]    ${screeenshot}
    Remove File    ${screeenshot}

Next order
    Click Button    order-another

Create a ZIP file of receipt PDF files
    ${zipFileName}    Set Variable    ${OUTPUT_DIR}${/}Orders.zip
    Archive Folder With Zip    ${TEMP_FILES_DIRECTORY}    ${zipFileName}

Delete archivied folder
    Remove Directory    ${TEMP_FILES_DIRECTORY}    recursive=${True}
