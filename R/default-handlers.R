#' @include plumber.R
default404Handler <- function(req, res){
  res$status <- 404
  list(error="404 - Resource Not Found")
}

defaultErrorHandler <- function(debug=FALSE){
  function(req, res, err){
    print(err)

    if (res$status == 200L){
      # The default is a 200. If that's still set, then we should probably override with a 500.
      # It's possible, however, than a handler set a 40x and then wants to use this function to
      # render an error, though.
      res$status <- 500
    }

    li <- list(error="500 - Internal server error")

    # Don't overly leak data unless they opt-in
    if (debug){
      li["message"] <- as.character(err)
    }

    li
  }
}
