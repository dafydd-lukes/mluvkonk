source("mluvkonk.R")

rows_per_page <- 25

prep_conc <- function(conc, page) {
  if (is.null(page)) return()
  rows <- ((page - 1) * rows_per_page + 1) : (page * rows_per_page)
  conc <- conc[rows, ]
  conc$row <- vapply(paste(conc$lc,
                           '<span class=kwic>',
                           conc$kwic,
                           '</span>',
                           conc$rc),
                     concLine2Html, character(1))
  conc[, c("meta", "row")]
}

shinyServer(function(input, output) {

  data <- reactive({
#     print(input$csv)
    if (is.null(input$csv)) {
      csv <- "demo.csv"
    } else {
      csv <- input$csv$datapath
    }
    conc <- read.csv2(csv, header = FALSE, stringsAsFactors = FALSE)
    names(conc) <- c("meta", "lc", "kwic", "rc")
    conc$row <- NA
    npages <- (nrow(conc) + rows_per_page - 1) %/% rows_per_page
    list(conc = conc, npages = npages, name = csv)
  })

  output$pager <- renderUI({
    sliderInput("page", "Vybrat stránku", min = 1, max = data()$npages, value = 1)
  })

  output$konk <- renderTable(prep_conc(data()$conc, input$page),
                             sanitize.text.function = identity,
                             include.colnames = FALSE)
})
