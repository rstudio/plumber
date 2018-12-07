#' @rdname serializers
#' @export
serializer_html <- function(...) {
  args <- list(...)
  if (length(args) > 0) {
    warning("'html' serializer does not interpret extra arguments")
  }
  # ... ignored
  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", "text/html; charset=utf-8")
      res$body <- val

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["html"]] <- serializer_html
