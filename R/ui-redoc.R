#' Mount Redoc UI
#' @noRd
mountRedoc <- function(pr, url, redoc_options = structure(list(), names = character())) {
  if (!requireNamespace("redoc", quietly = TRUE)) {
    stop("redoc must be installed for the Redoc UI to be displayed")
  }

  redocUrl <- paste0(url, "/__redoc__/")

  redoc_index <- function(...) {
    redoc::redoc_spec(
      "\' + window.location.origin + window.location.pathname.replace(/\\(__redoc__\\\\/|__redoc__\\\\/index.html\\)$/, '') + 'openapi.json' + \'",
      redoc_options)
  }
  for (path in c("/__redoc__/index.html", "/__redoc__/")) {
    pr$handle(
      "GET", path, redoc_index,
      serializer = serializer_html()
    )
  }
  pr$mount("/__redoc__", PlumberStatic$new(redoc::redoc_path()))

  return(redocUrl)
}

#' @include globals.R
.globals$interfaces[["redoc"]] <- mountRedoc
.globals$interfaces[["Redoc"]] <- mountRedoc
