#' @importFrom jsonlite validate toJSON
#' @noRd
safeFromJSON <- function(txt, simplifyVector = TRUE, ...) {
  if (!validate(txt)) {
    stop("Argument 'txt' is not a valid JSON string.")
  }
  jsonlite::parse_json(txt, simplifyVector, ...)
}
