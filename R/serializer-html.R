htmlSerializer <- function(val, req, res, errorHandler){
  tryCatch({
    res$setHeader("Content-Type", "text/html; charset=utf-8")
    res$body <- val

    return(res$toResponse())
  }, error=function(e){
    errorHandler(req, res, e)
  })
}

.globals$serializers[["html"]] <- htmlSerializer
