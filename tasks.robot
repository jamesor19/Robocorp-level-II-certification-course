# +
*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault

*** Variables ***
${Orders CSV URL}=    https://robotsparebinindustries.com/orders.csv

${Orders URL}=         https://robotsparebinindustries.com/#/robot-order

# +
*** Keywords ***
Open the robot order website
   Open Available Browser  ${Orders URL}
   
Get Orders
      ${secret}=    Get Secret    urls
      ${Orders CSV URL}=    Get Value From User    Url for robot orders to be created?   ${secret}[Orders CSV URl]
      Download    ${Orders CSV URL}  overwrite=True
      ${Orders Table}=   Read table from CSV    orders.csv  header=True
      [Return]  ${Orders Table}

Close Modal
    Click Button When Visible     //button[@class="btn btn-dark"]
    
    
Fill The Form
    [Arguments]        ${row}
    Scroll Element Into View  //button[@id="preview"]
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    xpath=(//input[@name="body"])[${row}[Body]]
    Input Text     xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${row}[Legs]
    Input Text    //input[@name="address"]    ${row}[Address]
    

Preview Robot
    Click Element    //button[@id="preview"]
    Wait Until Element Is Visible    //*[@id="robot-preview-image"]
    Scroll Element Into View  //*[@id="robot-preview-image"]
    Screenshot    id:robot-preview-image    ${CURDIR}\\images\\robot.png
    
Submit Order
       Click Element    //button[@id="order"]
        FOR    ${i}    IN RANGE    0    100
        ${sucessfullyOrdered}=    Is element visible    //button[@id="order-another"]
        Exit For Loop If    ${sucessfullyOrdered} == True
        Click Element    //button[@id="order"]
    END
    

Create Receipt
    [Arguments]               ${row}
    Wait Until Element Is Visible   //*[@id="receipt"]
    ${receipt}=      Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt}    ${CURDIR}\\receipts\\receipt_${row}[Order number].pdf
    Add Watermark Image To Pdf    ${CURDIR}\\images\\robot.png      ${CURDIR}\\receipts\\receipt_${row}[Order number].pdf         ${CURDIR}\\receipts\\receipt_${row}[Order number].pdf
    
    
Order Another Robot
    Click Element    //button[@id="order-another"]

Create a ZIP of the receipts
     Archive Folder With Zip    ${CURDIR}${/}receipts    receipts.zip
    
    

    
# -

*** Tasks ***
Open the website
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close Modal
        Fill the form    ${row}
        Preview robot
        Submit Order
        ${pdf}=    Create Receipt   ${row}
        Order Another Robot
    END
    Close All Browsers
    Create a ZIP of the receipts
