*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${TRUE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${BASE_URL}=        https://robotsparebinindustries.com/
${ARCHIVE_DIR}=     ${OUTPUT_DIR}${/}archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open browser and the langing page
    Delete archive from output directory if exists    ${ARCHIVE_DIR}
    ${orders}=    Get Orders
    FOR    ${order_row}    IN    @{orders}
        ${screenshot}=    Fill and submit the order    ${order_row}
        ${pdf}=    Store the receipt as a PDF file    ${OUTPUT_DIR}${/}${order_row}[Order number].pdf
        ${screenshot}=    Take a screenshot of the robot    ${OUTPUT_DIR}${/}${order_row}[Order number].png
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
    END
    Create archive directory if not exists    ${ARCHIVE_DIR}
    Move receipts to archive directory    ${OUTPUT_DIR}${/}*.pdf    ${ARCHIVE_DIR}
    Archive Folder With Zip    ${ARCHIVE_DIR}    ${OUTPUT_DIR}${/}all_receipts.zip
    Delete temp files from output directory    ${OUTPUT_DIR}${/}*.png
    [Teardown]    Close the browser


*** Keywords ***
Open browser and the langing page
    Open Available Browser    ${BASE_URL}

Accept terms
    Click Button    OK

Get Orders
    Download the CSV file
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv
    RETURN    ${orders}

Download the CSV file
    Download    ${BASE_URL}/orders.csv    ${OUTPUT_DIR}${/}orders.csv    overwrite=True

Fill and submit the order
    [Arguments]    ${row}
    Reset application state
    Accept terms
    Select From List By Value    head    ${row}[Head]
    Select Radio Button    body    id-body-${row}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    preview
    Wait Until Keyword Succeeds    5x    1s    Click submit order and assert success

Click submit order and assert success
    Click Button    Order
    Wait Until Element Is Visible    order-another

Reset application state
    Go To    ${BASE_URL}/#/robot-order
    Wait Until Element Is Visible    class:modal-header

Store the receipt as a PDF file
    [Arguments]    ${output_path}
    ${sales_results_html}=    Get Element Attribute    order-completion    outerHTML
    Html To Pdf    ${sales_results_html}    ${output_path}
    RETURN    ${output_path}

Take a screenshot of the robot
    [Arguments]    ${output_path}
    Capture Element Screenshot    robot-preview-image    ${output_path}
    RETURN    ${output_path}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${pdf}
    ...    ${screenshot}
    Add Files To Pdf    ${files}    ${pdf}
    Close All Pdfs

Close the browser
    Close Browser

Move receipts to archive directory
    [Arguments]    ${source}    ${destination}
    ${files}=    Find files    ${source}
    FOR    ${file}    IN    @{FILES}
        ${file_name}=    Get File Name    ${file}
        Move File    ${file}    ${destination}${/}${file_name}    ${True}
    END

Delete archive from output directory if exists
    [Arguments]    ${source}
    ${dir_exists}=    Does Directory Exist    ${source}
    IF    ${dir_exists}    Remove Directory    ${source}    ${True}

Delete temp files from output directory
    [Arguments]    ${source}
    ${files}=    Find files    ${source}
    FOR    ${file}    IN    @{FILES}
        Remove File    ${file}
    END

Create archive directory if not exists
    [Arguments]    ${directory}
    ${directory_exists}=    Does directory not exist    ${directory}
    IF    ${directory_exists}    Create directory    ${directory}
