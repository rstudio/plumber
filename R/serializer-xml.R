xmlSerializer <- function(val, req, res, errorHandler){
  #if (!requireNamespace("XML", quietly = TRUE)) {
  #  stop("The XML package is not available but is required in order to use the XML serializer.",
  #       call. = FALSE)
  #}

  stop("XML serialization not yet implemented")
}

.globals[["xml"]] <- xmlSerializer
