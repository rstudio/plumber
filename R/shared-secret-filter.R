#' @noRd
sharedSecretFilter <- function(req){
  secret <- getOption("plumber.sharedSecret")
  if (!is.null(secret)){
    supplied <- req$HTTP_SHINY_SHARED_SECRET
    if (!identical(supplied, secret)){
      stop("The provided shared secret did not match expected secret.")
    }
  }

  forward()
}
