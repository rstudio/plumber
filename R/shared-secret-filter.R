#' @noRd
sharedSecretFilter <- function(req, res){
  secret <- getOption("plumber.sharedSecret", NULL)
  if (!is.null(secret)){
    supplied <- req$HTTP_PLUMBER_SHARED_SECRET
    if (!identical(supplied, secret)){
      res$status <- 400
      return(list(error = "Shared secret mismatch."))
    }
  }

  forward()
}
