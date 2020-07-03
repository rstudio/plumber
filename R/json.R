#' @importFrom jsonlite validate fromJSON toJSON
#' @noRd
safeFromJSON <- function(txt, ...) {
  if (!validate(txt)) {
    stop("Argument 'txt' is not a valid JSON string.")
  }
  fromJSON(txt, ...)
}
