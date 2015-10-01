require(shiny)
require(tidyr)
require(stringr)
require(ggvis)
source("mluvkonk.R")

## FOR INTERACTIVE TESTING:
# conc <- read.csv2("demo.csv", header = FALSE, stringsAsFactors = FALSE)
# conc <- read.csv2("prekryvy.csv", header = FALSE, stringsAsFactors = FALSE)
# names(conc) <- c("meta", "lc", "kwic", "rc")
# inp <- list(page = 2, rows_per_page = 10)
# bar <- prep_conc(conc, inp)

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

highlight_kwic <- Vectorize(function(kwic_segment) {
  # wrap inner "</sp><sp ...>" sequences with </span> ... <span>"; NOTE: the
  # class attribute is NOT wrapped with quotes, because the other attributes as
  # exported from KonText aren't either at this point; concLine2Html takes care
  # of this
  kwic_segment <- gsub("(</.*?><.*?>)",
                       "</span>\\1<span class=kwic>",
                       kwic_segment)
  # add outer "<span> ... </span>"
  paste("<span class=kwic>", kwic_segment, "</span>", sep = "")
})

pasteConcLine <- function(conc) {
  paste(conc$lc,
        highlight_kwic(conc$kwic),
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

  # stuff that gets done / updated when new data is loaded
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
    numericInput("page", sprintf("Zvolte stranu (celkem %d):", npages),
                 min = 1, max = npages, value = 1, step = 1)
  })

  output$konk <- renderTable(
    {
      p <- input$page
      np <- data()$npages
      validate(need(is.integer(p) && p > 0 && p <= np,
                    sprintf("Jako stranu zvolte prosím celé číslo v rozmezí %d až %d.", 1, np)))
      prep_conc(data()$conc, input)
    },
    sanitize.text.function = identity,
    include.colnames = FALSE)

  output$name <- renderText(data()$name)

  # = output$freq (the freq dist chart)
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
      add_axis("x", title = title,
               title_offset = 100,
               properties = axis_props(
                 labels = list(angle = 45, align = "left") #, fontSize = 20)
               )) %>%
      add_axis("y", title = "Absolutní frekvence", title_offset = 50)
  }) %>% bind_shiny("freq")
})
