adjacent2na <- function(only = c()) {
  prev <- NA

  function(curr) {
    if (is.na(curr)) {
      stop("adjacent2na uses NA values in a special way.
  Please remove them before proceeding.")
    }
    if (is.na(prev)) {
      prev <<- curr
      return(curr)
    } else if (curr == prev) {
      prev <<- curr
      if (curr %in% only)
        return(NA)
      else if (length(only) == 0)
        return(NA)
      else
        return(curr)
    } else {
      prev <<- curr
      return(curr)
    }
  }
}

collapse_adjacent <- function(vector, only = c()) {
  # this should be vapply, but I can't for the love of God figure out how to
  # allow NAs in the output
  vector <- sapply(vector, adjacent2na(only))#, vector[1])
  vector[!is.na(vector)]
}

# whitespace <- function(string) {
#   string <- gsub("> +| +<", "", string)
#   gsub(" ", "&nbsp;", string)
# }

concLine2Html <- function(conc_row) {
  # wrap attr values with quotes
  conc_row <- gsub("=([^ >]*)", '="\\1"', conc_row)
  # if the row does not start with a <sp> tag, add one
  if (!grepl("^<sp", conc_row)) conc_row <- paste0('<sp num="??" prekryv="N/A">', conc_row)
  # if the row does not end with a </sp> tag, add one
  if (!grepl("</sp>$", conc_row)) conc_row <- paste0(conc_row, '</sp>')
  # remove any potential <seg> and <doc> tags
  conc_row <- gsub("</?(doc|seg)[^>]*>", "", conc_row)
  # add a root node
  conc_row <- paste0("<root>", conc_row, "</root>")
#   cat("\n\n")
#   cat(conc_row)
  root <- XML::xmlRoot(XML::xmlParse(conc_row, asText = TRUE))
#   return(root)
  attrs <- XML::xmlSApply(root, XML::xmlAttrs)
#   return(attrs)
  speakers <- unique(attrs["num", ])
  num_speakers <- length(speakers)
  num_cells <- length(collapse_adjacent(attrs["prekryv", ], only = "ano"))
  table <- matrix(nrow = num_speakers, ncol = num_cells)
  row.names(table) <- speakers
  nodes <- XML::xmlChildren(root)

  prev_prekryv <- "N/A"
  col <- 0
  for (i in seq_along(nodes)) {
    node <- nodes[[i]]
    attrs <- XML::xmlAttrs(node)
    if (prev_prekryv != "ano" || attrs["prekryv"] != "ano") {
      col <- col + 1
      prev_prekryv <- attrs["prekryv"]
    } else {
      prev_prekryv <- attrs["prekryv"]
    }
#     table[attrs["num"], col] <- XML::xmlValue(node, trim = TRUE)
    table[attrs["num"], col] <- XML::toString.XMLNode(node)
  }

  # XML::toHtml can also be used here instead of xtable
  paste(capture.output(print(xtable::xtable(table), type = "html",
                             include.colnames = FALSE,
                             sanitize.text.function = identity,
                             html.table.attributes = "")),
        collapse = "\n")
}
