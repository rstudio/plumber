#' @include globals.R
#' @rdname serializers
#' @param ... extra arguments supplied to respective internal serialization function.
#' @export
serializer_json <- function(...) {
  function(val, req, res, errorHandler) {
    tryCatch({
      json <- jsonlite::toJSON(val, ...)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}
.globals$serializers[["json"]] <- serializer_json

#' @include globals.R
#' @rdname serializers
#' @inheritParams jsonlite::toJSON
#' @export
serializer_unboxed_json <- function(auto_unbox = TRUE, ...) {
  serializer_json(auto_unbox = auto_unbox, ...)
}

.globals$serializers[["unboxedJSON"]] <- serializer_unboxed_json
