xmlSerializer <- function(){
  function(val, req, res, errorHandler){
    #if (!requireNamespace("XML", quietly = TRUE)) {
    #  stop("The XML package is not available but is required in order to use the XML serializer.",
    #       call. = FALSE)
    #}

    stop("XML serialization not yet implemented. Please see the discussion at https://github.com/trestletech/plumber/issues/65")
  }
}

.globals$serializers[["xml"]] <- xmlSerializer
