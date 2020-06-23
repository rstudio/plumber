#' @rdname serializers
#' @export
serializer_csv <- function(...) {
  if (!requireNamespace("readr", quietly = TRUE)) {
    stop("`readr` must be installed for `serializer_csv` to work")
  }

  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", "text/plain; charset=UTF-8")
      res$body <- readr::format_csv(val, ...)
      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}

#' @include globals.R
.globals$serializers[["csv"]] <- serializer_csv
