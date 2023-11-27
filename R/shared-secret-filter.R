#' @noRd
sharedSecretFilter <- function(req, res){
  secret <- get_option_or_env("plumber.sharedSecret", NULL)
  if (!is.null(secret)){
    supplied <- req$HTTP_PLUMBER_SHARED_SECRET
    if (!identical(supplied, secret)){
      res$status <- 400
      # Force the route to return as unboxed json
      res$serializer <- serializer_unboxed_json()
      # Using output similar to `defaultErrorHandler()`
      li <- list(error = "400 - Bad request")

      # Don't overly leak data unless they opt-in
      if (is.function(req$pr$getDebug) && isTRUE(req$pr$getDebug())) {
        li$message <- "Shared secret mismatch"
      }
      return(li)
    }
  }

  forward()
}
