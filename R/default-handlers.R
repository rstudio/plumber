#' @include plumber.R
default404Handler <- function(req, res){
  res$status <- 404
  list(error="404 - Resource Not Found")
}

defaultErrorHandler <- function(debug=FALSE){
  function(req, res, err){
    print(err)
    res$status <- 500

    li <- list(error="500 - Internal server error")

    # Don't overly leak data unless they opt-in
    if (debug){
      li["message"] <- as.character(err)
    }

    li
  }
}
