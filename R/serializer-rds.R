#' @rdname serializers
#' @export
serializer_r_object <- function(){
  function(val, req, res, errorHandler){
    tryCatch({
      res$setHeader("Content-Type", "application/octet-stream")
      res$body <- base::serialize(val, NULL, ascii = FALSE)
      return(res$toResponse())
    }, error = function(e){
      errorHandler(req, res, e)
    })
  }
}

.globals$serializers[["rObject"]] <- serializer_r_object
