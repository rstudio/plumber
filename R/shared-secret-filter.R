#' @noRd
sharedSecretFilter <- function(req, res){
  secret <- getOption("plumber.sharedSecret", NULL)
  if (!is.null(secret)){
    supplied <- req$HTTP_PLUMBER_SHARED_SECRET
    if (!identical(supplied, secret)){
      res$status <- 400
      stop("The provided shared secret did not match expected secret.")
    }
  }

  forward()
}
