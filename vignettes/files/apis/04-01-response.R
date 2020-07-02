#' Endpoint that bypasses serialization
#' @get /
function(res){
  res$body <- "Literal text here!"

  res
}
