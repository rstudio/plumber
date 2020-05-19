#' @rdname serializers
#' @export
serializer_yaml <- function(...) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("yaml must be installed for the yaml serializer to work")
  }
  function(val, req, res, errorHandler) {
    tryCatch({
      yaml <- yaml::as.yaml(val, ...)
      res$setHeader("Content-Type", "application/x-yaml")
      res$body <- yaml

      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}

#' @include globals.R
.globals$serializers[["yaml"]] <- serializer_yaml
