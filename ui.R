require(markdown)
require(ggvis)

shinyUI(fluidPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "mluvkonk.css")
  ),

  includeHTML("www/forkme.html"),

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
             span("Zdrojový soubor konkordance: ",
                  code(textOutput("name", inline = TRUE))),
             tableOutput("konk")
    ),

    tabPanel("Statistika",
             br(),
             sidebarLayout(
               sidebarPanel(
                 selectInput("freq_meta_type_select", "Typ metainformací:",
                             choices = c()),
                 checkboxInput("by_kwic_variants",
                               "Rozdělit podle variant KWIC")
               ),
               mainPanel(
                 h1("Frekvenční distribuce"),
                 ggvisOutput("freq")
               )
             )
    ),

    tabPanel("Nápověda",
             br(),
             div(class = "wrap-text",
                 shiny::includeMarkdown("README.md")
             )
    )
  )
))
