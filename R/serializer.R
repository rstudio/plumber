#' @export
addSerializer <- function(name, serializer){
  if (is.null(.globals$serializers)){
    .globals$serializers <- list()
  }
  if (!is.null(.globals$serializers[[name]])){
    stop ("Already have a serializer by the name of ", name)
  }
  .globals$serializers[[name]] <- serializer
}

nullSerializer <- function(val, req, res, errorHandler){
  tryCatch({
    res$body <- val

    return(res$toResponse())
  }, error=function(e){
    errorHandler(req, res, e)
  })
}

.globals$serializers[["null"]] <- nullSerializer
