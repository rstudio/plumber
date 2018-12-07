#' @include globals.R
#' @rdname serializers
#' @param na How should NA values be encoded?
#' @export
serializer_json <- function(na = "null"){
  purrr::partial(function(val, req, res, errorHandler, na){

    tryCatch({
      json <- jsonlite::toJSON(val, na = na)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }, na = na, .lazy = FALSE)
}
.globals$serializers[["json"]] <- serializer_json

#' @include globals.R
#' @rdname serializers
#' @export
serializer_unboxed_json <- function(na = "null"){
  purrr::partial(function(val, req, res, errorHandler, na){
    tryCatch({
      json <- jsonlite::toJSON(val, na = na, auto_unbox = TRUE)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }, na = na, .lazy = FALSE)
}

.globals$serializers[["unboxedJSON"]] <- serializer_unboxed_json
