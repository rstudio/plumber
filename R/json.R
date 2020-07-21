#' @importFrom jsonlite parse_json
#' @noRd
safeFromJSON <- function(txt) {
  parse_json(txt, simplifyVector = TRUE)
}
