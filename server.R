source("mluvkonk.R")

# conc <- read.csv2("demo.csv", header = FALSE, stringsAsFactors = FALSE)
# names(conc) <- c("meta", "lc", "kwic", "rc")

rows_per_page <- function(input) {
  rpp <- input$rows_per_page
  if (is.na(rpp)) {
    return(25)
  } else {
    return(rpp)
  }
}

prep_conc <- function(conc, input) {
  page <- input$page
  if (is.null(page)) return()
  rows_per_page <- rows_per_page(input)
  rows <- ((page - 1) * rows_per_page + 1) : min((page * rows_per_page), nrow(conc))
  print(rows)
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
    rows_per_page <- rows_per_page(input)
    if (is.null(input$csv)) {
      csv <- "demo.csv"
      name <- csv
    } else {
      csv <- input$csv$datapath
      name <- input$csv$name
    }
    conc <- read.csv2(csv, header = FALSE, stringsAsFactors = FALSE)
    names(conc) <- c("meta", "lc", "kwic", "rc")
    conc$row <- NA
    npages <- (nrow(conc) + rows_per_page - 1) %/% rows_per_page
    list(conc = conc, npages = npages, name = name)
  })

  output$pager <- renderUI({
    sliderInput("page", "Vybrat stránku:", min = 1, max = data()$npages,
                value = 1, step = 1)
  })

  output$konk <- renderTable(prep_conc(data()$conc, input),
                             sanitize.text.function = identity,
                             include.colnames = FALSE)

  output$name <- renderText(data()$name)
})
