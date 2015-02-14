require(shiny)
require(tidyr)
require(stringr)
require(ggvis)
source("mluvkonk.R")

# conc <- read.csv2("demo.csv", header = FALSE, stringsAsFactors = FALSE)
# conc <- read.csv2("topoparo.csv", header = FALSE, stringsAsFactors = FALSE)
# names(conc) <- c("meta", "lc", "kwic", "rc")
# inp <- list(page = 2, rows_per_page = 10)

meta2colname <- function(name, names) as.name(letters[grep(name, names)])

bar_tooltip <- function(bar) {
  last <- length(bar)
  second_to_last <- last - 1
  count <- paste("frekvence: ", bar[last] - bar[second_to_last])
  start <- bar[-c(last, second_to_last)]
  paste(c(start, count), collapse = "<br/>")
}

determine_rpp <- function(input, conc) {
  rpp <- input$rows_per_page
  len <- nrow(conc)
  if (is.na(rpp)) {
    return(min(25, len))
  } else {
    return(min(rpp, len))
  }
}

pasteConcLine <- function(conc) {
  paste(conc$lc,
        '<span class=kwic>',
        conc$kwic,
        '</span>',
        conc$rc)
}

prep_conc <- function(conc, input) {
  page <- input$page
  if (is.null(page)) return()
  rows_per_page <- determine_rpp(input, conc)
  conc_len <- nrow(conc)
  start_index <- (page - 1) * rows_per_page + 1
  start_index <- if (start_index >= conc_len) 1 else start_index
  rows <- start_index : min((page * rows_per_page), conc_len)
  conc <- conc[rows, ]
  conc$row <- vapply(pasteConcLine(conc),
                     concLine2Html, character(1))
  conc[, c("meta", "row")]
}

shinyServer(function(input, output, session) {

  data <- reactive({
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
    rows_per_page <- determine_rpp(input, conc)

    meta_names <- paste0("typ: ", str_split(conc$meta[1], ",")[[1]], ", ...")
    # use letters as proxy colnames for the more descriptive meta_names, which
    # work in funky ways when selecting columns using dplyr
    conc <- separate_(conc, "meta", letters[1:length(meta_names)], ",",
                      remove = FALSE)
    npages <- (nrow(conc) + rows_per_page - 1) %/% rows_per_page

    updateSelectInput(session, "freq_meta_type_select",
                      choices = meta_names)

    list(conc = conc, npages = npages, name = name, meta = meta_names)
  })

  # this can be done more easily using updateSliderInput, unless freeform logic
  # (as in this case) is required (?)
  output$pager <- renderUI({
    npages <- (data()$npages)
    if (npages > 1)
      sliderInput("page", "Vybrat stránku:", min = 1, max = npages,
                  value = 1, step = 1)
    else
      tags$label("Počet stran: 1.")
  })

  output$konk <- renderTable(prep_conc(data()$conc, input),
                             sanitize.text.function = identity,
                             include.colnames = FALSE)

  output$name <- renderText(data()$name)

  reactive({
    conc <- data()$conc
    meta <- input$freq_meta_type_select
    meta_names <- data()$meta
    col <- meta2colname(if (meta != "") meta else meta_names[1], meta_names)
    kwic <- if (input$by_kwic_variants) as.name("kwic") else ""
    title <- paste0("Skupiny podle metainformací (", meta, ")")
    ggvis(conc, prop("x", col), fill = prop("fill", kwic)) %>%
      layer_bars() %>%
      add_tooltip(bar_tooltip, on = "hover") %>%
      add_axis("x", title = title) %>%
      add_axis("y", title = "Absolutní frekvence")
  }) %>% bind_shiny("freq")
})
