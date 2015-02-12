require(markdown)

shinyUI(fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "mluvkonk.css")
  ),

  titlePanel("MluvKonk"),

  tabsetPanel(
    tabPanel("Konkordance",
             inputPanel(
               fileInput('csv', 'Nahrát vlastní konkordanci:',
                         accept = c(
                           'text/csv',
                           'text/comma-separated-values'
                         )
               ),
               uiOutput("pager"),
               sliderInput("rows_per_page", "Počet výsledků na stránku:", 25,
                           min = 1, max = 100)
             ),
             withTags(span("Zdrojový soubor konkordance: ",
                           code(textOutput("name", inline = TRUE)))),
             tableOutput("konk")
    ),

    tabPanel("Nápověda",
             tags$div(class = "wrap-text",
                      shiny::includeMarkdown("README.md")
             )
    )
  )
))
