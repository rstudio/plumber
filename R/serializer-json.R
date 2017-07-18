#' @include globals.R
#' @rdname serializers
#' @export
jsonSerializer <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      json <- jsonlite::toJSON(val)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}
.globals$serializers[["json"]] <- jsonSerializer

#' @include globals.R
#' @rdname serializers
#' @export
unboxedJsonSerializer <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      json <- jsonlite::toJSON(val, auto_unbox = TRUE)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["unboxedJSON"]] <- unboxedJsonSerializer
