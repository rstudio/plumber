#' @include plumber.R
default404Handler <- function(req, res){
  res$status <- 404
  list(error="404 - Resource Not Found")
}

defaultErrorHandler <-function(req, res, err){
  print(err)
  res$status <- 500

  li <- list(error="500 - Internal server error")

  if (.globals$debug){
    li["message"] <- err
  }

  li
}
