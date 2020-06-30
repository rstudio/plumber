#' Example of throwing an error
#' @get /simple
function(){
  stop("I'm an error!")
}

#' Generate a friendly error
#' @get /friendly
function(res){
  msg <- "Your request did not include a required parameter."
  res$status <- 400 # Bad request
  list(error=jsonlite::unbox(msg))
}
