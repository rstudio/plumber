#' @rdname serializers
#' @param type The value to provide for the `Content-Type` HTTP header.
#' @param disposition The value to provide for the `Content-Disposition` HTTP header.
#' @export
serializer_content_type_disposition <- function(type,disposition) {
  if (missing(type)){
    stop("You must provide the custom content type to the serializer_content_type_disposition")
  }
  if (missing(disposition)){
    stop("You must provide the custom content disposition to the serializer_content_type_disposition")
  }
  
  function(val, req, res, errorHandler){
    tryCatch({
      res$setHeader("Content-Type", type)
	  res$setHeader("Content-Disposition", disposition)
      res$body <- val

      return(res$toResponse())
    }, error=function(e){
      errorHandler(req, res, e)
    })
  }
}

#' @include globals.R
.globals$serializers[["contentType"]] <- serializer_content_type_disposition