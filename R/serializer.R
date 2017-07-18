#' Plumber Serializers
#'
#' Serializers are used in Plumber to transform the R object produced by a
#' filter/endpoint into an HTTP response that can be returned to the client. See
#' [here](https://book.rplumber.io/rendering-and-output.html#serializers) for
#' more details on Plumber serializers and how to customize their behavior.
#' @name serializers
#' @rdname serializers
NULL

#' Add a Serializer
#'
#' A serializer is responsible for translating a generated R value into output
#' that a remote user can understand. For instance, the \code{serializer_json}
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



nullSerializer <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      res$body <- val

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["null"]] <- nullSerializer
