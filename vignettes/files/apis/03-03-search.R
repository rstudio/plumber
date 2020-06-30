#' @get /
search <- function(q="", pretty=0){
  paste0("The q parameter is '", q, "'. ",
         "The pretty parameter is '", pretty, "'.")
}
