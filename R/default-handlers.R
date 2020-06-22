#' @include plumber.R
default404Handler <- function(req, res){
  res$status <- 404L
  list(error="404 - Resource Not Found")
}

defaultErrorHandler <- function(){
  function(req, res, err){
    print(err)

    li <- list()

    if (res$status == 200L){
      # The default is a 200. If that's still set, then we should probably override with a 500.
      # It's possible, however, than a handler set a 40x and then wants to use this function to
      # render an error, though.
      res$status <- 500
      li$error <- "500 - Internal server error"
    } else {
      li$error <- "Internal error"
    }


    # Don't overly leak data unless they opt-in
    if (getOption("plumber.debug", FALSE)) {
      li["message"] <- as.character(err)
    }

    li
  }
}
