#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToSwaggerType <- function(type){
  if (type == "bool" || type == "logical"){
    return("boolean")
  } else if (type == "double" || type == "numeric"){
    return("number")
  } else if (type == "int"){
    return("integer")
  } else if (type == "character"){
    return("string")
  } else {
    stop("Unrecognized type: ", type)
  }
}
