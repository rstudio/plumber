#' @importFrom jsonlite parse_json
#' @noRd
safeFromJSON <- function(txt, simplifyVector = TRUE, ...) {
  parse_json(txt, simplifyVector = simplifyVector, ...)
}
