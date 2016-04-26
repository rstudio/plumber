contentTypeSerializer <- function(type){
  if (missing(type)){
    stop("You must provide the custom content type to the contentTypeSerializer")
  }
  function(val, req, res, errorHandler){
    tryCatch({
      res$setHeader("Content-Type", type)
      res$body <- val

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["contentType"]] <- contentTypeSerializer
