safeFromJSON <- function(txt, ...) {
  if (!jsonlite::validate(txt)) {
    stop("Argument 'txt' is not a valid JSON string.")
  }

  jsonlite::fromJSON(txt, ...)
}
