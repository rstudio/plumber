#' Add a Serializer
#'
#' A serializer is responsible for translating a generated R value into output
#' that a remote user can understand. For instance, the \code{jsonSerializer}
#' serializes R objects into JSON before returning them to the user. The list of
#' available serializers in plumber is global.
#'
#' @param name The name of the serializer (character string)
#' @param serializer The serializer to be added.
#'
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
