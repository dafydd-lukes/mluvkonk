adjacent2na <- function(only = c(), max) {
  prev <- NA
  count <- 1

  function(curr) {
#     print(prev)
#     print(count)
    if (is.na(curr)) {
      stop("adjacent2na uses NA values in a special way.
  Please remove them before proceeding.")
    } else if (count == max) {
    # if count of repeated instances has reached max, start over as if there was
    # no preceding item (greedy approach)
      prev <<- curr # don't forget this!!!
      count <<- 1
      return(curr)
    } else if (is.na(prev)) {
      prev <<- curr
      return(curr)
    } else if (curr == prev) {
      prev <<- curr
      count <<- count + 1
      if (length(only) == 0 || curr %in% only)
        return(NA)
      else
        return(curr)
    } else {
      prev <<- curr
      return(curr)
    }
  }
}

collapse_adjacent <- function(vector, only = c(), max = 2) {
  # this should be vapply, but I can't for the love of God figure out how to
  # allow NAs in the output
  vector <- sapply(vector, adjacent2na(only, max))#, vector[1])
  vector # [!is.na(vector)]
}

# whitespace <- function(string) {
#   string <- gsub("> +| +<", "", string)
#   gsub(" ", "&nbsp;", string)
# }

concLine2Html <- function(conc_row) {
#   print(conc_row)
  # wrap attr values with quotes
  conc_row <- gsub("=([^ >]*)", '="\\1"', conc_row)
  # if the row does not start with a <sp> tag, add one; its prekryv value is
  # determined by whether the lc starts with an odd number of adjacent
  # 'prekryv=ano' (→ 'prekryv=ano') or not
  lc_start <- sub('(.*?)prekryv="ne".*', "\\1", conc_row)
  if ((stringr::str_count(lc_start, 'prekryv="ano"') %% 2) == 0)
    first_sp <- '<sp num="??" prekryv="N/A">'
  else
    first_sp <- '<sp num="??" prekryv="ano">'
  if (!grepl("^<sp", conc_row)) conc_row <- paste0(first_sp, conc_row)
  # if the row does not end with a </sp> tag, add one
  if (!grepl("</sp>$", conc_row)) conc_row <- paste0(conc_row, '</sp>')
  # remove any potential <seg> and <doc> tags
  conc_row <- gsub("</?(doc|seg)[^>]*>", "", conc_row)
#   cat(conc_row)
#   cat("\n\n")
  # add a root node
  conc_row <- paste0("<root>", conc_row, "</root>")
  root <- tryCatch(
    XML::xmlRoot(XML::xmlParse(conc_row, asText = TRUE)),
    error = function(e) {
      stop(paste(e, "The XML parser failed on this row:", conc_row,
                 sep = "\n\n"))
    }
  )
#   return(root)
  attrs <- XML::xmlSApply(root, XML::xmlAttrs)
#   return(attrs)
  speakers <- unique(attrs["num", ])
  num_speakers <- length(speakers)
#   return(collapse_adjacent(attrs["prekryv", ], only = "ano"))
  num_cells <- length(collapse_adjacent(attrs["prekryv", ], only = "ano"))
  table <- matrix(nrow = num_speakers, ncol = num_cells)
  # name table rows according to speaker numbers (sorted)
  row.names(table) <- sort(speakers)
  nodes <- XML::xmlChildren(root)
#   print(table)

  # only two adjacent <sp prekryv=ano/> can belong to the same prekryv
  count_prekryv <- 0
  col <- 0
  for (i in seq_along(nodes)) {
    node <- nodes[[i]]
    attrs <- XML::xmlAttrs(node)
#     print(attrs)
#     print(count_prekryv)
    if (attrs["prekryv"] != "ano") {
      col <- col + 1
      count_prekryv <- 0
    } else if (count_prekryv == 0) {
      # if we're in <sp prekryv=ano/> but count_prekryv == 0, we also need to
      # increment col, otherwise we would overlap with the preceding <sp
      # prekryv=ne/>
      col <- col + 1
      count_prekryv <- (count_prekryv + 1) %% 2
    } else {
      count_prekryv <- (count_prekryv + 1) %% 2
    }
#     print(attrs["num"])
#     print(col)
#     print(node)
    table[attrs["num"], col] <- XML::toString.XMLNode(node)
  }

  # XML::toHtml can also be used here instead of xtable
  paste(capture.output(print(xtable::xtable(table), type = "html",
                             include.colnames = FALSE,
                             sanitize.text.function = identity,
                             html.table.attributes = "",
                             comment = FALSE)),
        collapse = "\n")
}
