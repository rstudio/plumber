#' @noRd
#' @include globals.R
jsonSerializer <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      json <- rjson::toJSON(val)

      res$setHeader("Content-Type", "application/json")
      res$body <- json

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["json"]] <- jsonSerializer
