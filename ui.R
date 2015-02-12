require(markdown)

shinyUI(fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "mluvkonk.css")
  ),

  titlePanel("MluvKonk"),

  tabsetPanel(
    tabPanel("Konkordance",
             inputPanel(
               fileInput('csv', 'Nahrát vlastní konkordanci',
                         accept = c(
                           'text/csv',
                           'text/comma-separated-values'
                         )
               ),
               uiOutput("pager"),
               tags$label("Zobrazuje se 25 výsledků na stránku.")
             ),
             tableOutput("konk")
    ),

    tabPanel("Nápověda",
             tags$div(class = "wrap-text",
                      shiny::includeMarkdown("README.md")
             )
    )
  )
))
