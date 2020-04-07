#' @rdname serializers
#' @param ... extra arguments supplied to respective internal serialization function.
#' @export
serializer_csv <- function(...) {
  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", "text/plain")
      res$body <- readr::format_csv(val)
      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}

#' @include globals.R
.globals$serializers[["csv"]] <- serializer_csv
