*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive
Library             Collections
Library             RPA.FileSystem
Library             RPA.RobotLogListener


*** Variables ***
${url}              https://robotsparebinindustries.com/#/robot-order

${img_folder}       ${CURDIR}${/}image_files
${pdf_folder}       ${CURDIR}${/}pdf_files
${output_folder}    ${CURDIR}${/}output

${orders_file}      ${CURDIR}${/}orders.csv
${zip_file}         ${pdf_folder}${/}pdf_archive.zip
${csv_url}          https://robotsparebinindustries.com/orders.csv


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Check Folders
    Open the robot order website
    ${orders}    Get orders
    Fill the order using the data from the csv file    ${orders}
    Create a ZIP file of the receipts
    Log Out And Close The Browser


*** Keywords ***
Check Folders
    Log To console    Creando y limpiando las carpetas donde estaran las resultados.

    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}
    Create Directory    ${output_folder}

    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder}

Open the robot order website
    Log To console    Abriendo pagina web
    Open Available Browser    ${url}

Get orders
    Log To console    Descargando y leyendo archivo de ordenes
    Download    url=${csv_url}    target_file=${orders_file}    overwrite=True
    ${order_datatable}    Read table from CSV    path=${orders_file}
    RETURN    ${order_datatable}

Close the annoying modal
    Log To console    Cerrando ventana de inicio
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Wait And Click Button    ${btn_yep}

Fill the order using the data from the csv file
    [Arguments]    ${orders}
    Log To console    Ingresando datos

    ${orders}    Get orders
    FOR    ${RowOrder}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${RowOrder}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${orderid}    ${fullname_imgfile}    Take a screenshot of the robot image
        ${pdf_filename}    Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${fullname_imgfile}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
    Log To console    Items procesados

Fill the form
    [Arguments]    ${RowOrder}

    # Extrae los valores de la Row a procesar
    ${Number_Order}    Set Variable    ${RowOrder}[Order number]
    ${Head_Order}    Set Variable    ${RowOrder}[Head]
    ${Body_Order}    Set Variable    ${RowOrder}[Body]
    ${Legs_Order}    Set Variable    ${RowOrder}[Legs]
    ${Address_Order}    Set Variable    ${RowOrder}[Address]

    # Define variables para los campos en la pagina web
    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]

    Log To console    Procesando orden: ${Number_Order}

    # Ingresar Datos de la Orden.
    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${Head_Order}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${Body_Order}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${Legs_Order}

    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${Address_Order}

Preview the robot
    # Define variables para los campos en la pagina web de previsualización del bot
    Log To console    Revisando la previsualización de la orden
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    # Define variables para los campos en la pagina web de la orden del bot
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    # No genera captura de pantalla si falla
    Mute Run On Failure    La pagina no cargo la previsualización

    # Crea el pedido. Deberia aparecer el recibo
    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take a screenshot of the robot image
    # Define variables para los campos en la pagina web del recibo del bot
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]

    # Esperar a que la pagina cargue
    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}

    # Obtener el ID de la orden
    ${orderid}    Get Text    //*[@id="receipt"]/p[1]

    # Crear el nombre del archivo
    Set Local Variable    ${fullname_imgfile}    ${img_folder}${/}${orderid}.png

    Log To Console    Guardando captura de pantalla para: ${fullname_imgfile}
    Capture Element Screenshot    ${img_robot}    ${fullname_imgfile}
    RETURN    ${orderid}    ${fullname_imgfile}

    # Regresa el ID de la orden y el nombre completo del archivo de la imagen

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}
    Log To Console    Guardando recibo como un archivo PDF

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Recibo: ${ORDER_NUMBER}
    ${order_receipt_html}    Get Element Attribute    //*[@id="receipt"]    outerHTML

    Set Local Variable    ${FullFileName}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${FullFileName}
    RETURN    ${FullFileName}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}

    Log To Console    Ingresando la imagen ${IMG_FILE} en el archivo pdf ${PDF_FILE}

    # Abrir PDF
    Open PDF    ${PDF_FILE}

    # Lista de las ordenes que se agregan al PDF
    @{myfiles}    Create List    ${IMG_FILE}:x=0,y=0

    # Agregando archivo al PDF
    Add Files To PDF    ${myfiles}    ${PDF_FILE}    ${True}

    # Cerrando PDF
    Close PDF    ${PDF_FILE}

Go to order another robot
    Log To Console    Orden completada y guardada, pasando a la siguiente
    # Define variables para los campos en la pagina web del recibo del bot para ir a la siguiente orden
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Create a Zip File of the Receipts
    Log To console    Creando sip con archivos PDF
    Archive Folder With ZIP    ${pdf_folder}    ${zip_file}    recursive=True    include=*.pdf

Log Out And Close The Browser
    Log To console    Cerrando navegador
    Close Browser
