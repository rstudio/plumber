#' @rdname serializers
#' @inheritParams base::serialize
#' @export
serializer_rds <- function(version = "2", ascii = FALSE, ...) {
  function(val, req, res, errorHandler) {
    tryCatch({
      res$setHeader("Content-Type", "application/octet-stream")
      res$body <- base::serialize(val, NULL, ascii = ascii, ...)
      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["rObject"]] <- serializer_r_object

#' @rdname serializers
#' @inheritParams base::serialize
#' @export
serializer_rds3 <- function(version = "3", ascii = FALSE, ...) {
  serializer_rds(version = version, ascii = ascii, ...)
}
