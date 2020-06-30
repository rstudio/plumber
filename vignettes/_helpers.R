library(plumber)

knitr::opts_chunk$set(
  collapse = FALSE,
  comment = "#>"
)

code_chunk <- function(output, language=""){
  cat(paste0("```",language,"\n"))
  cat(output)
  cat("\n```\n")
}

# #' Include an external R file with syntax highlighting in the doc
# include_r <- function(file){
#   code_chunk(paste0(readLines(file), collapse="\n"), language="r")
# }

#' Serialize an object into JSON the same way that plumber would.
#' This way if the logic changes we consolidate all references to here.
json_serialize <- function(obj){
  jsonlite::toJSON(obj, auto_unbox = FALSE, pretty = TRUE)
}
