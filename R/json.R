#' @importFrom jsonlite validate
#' @importFrom jsonlite fromJSON
safeFromJSON <- function(txt, ...){
  if (!jsonlite::validate(txt)){
    stop("Argument 'txt' is not a valid JSON string.")
  } else {
    jsonlite::fromJSON(txt, ...)
  }
}
