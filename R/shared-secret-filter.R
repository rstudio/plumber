#' @noRd
sharedSecretFilter <- function(req, res){
  secret <- getOption("plumber.sharedSecret", NULL)
  if (!is.null(secret)){
    supplied <- req$HTTP_PLUMBER_SHARED_SECRET
    if (!identical(supplied, secret)){
      res$status <- 400
      # Force the route to return as unboxed json
      res$serializer <- serializer_unboxed_json()
      return(list(error = "Shared secret mismatch."))
    }
  }

  forward()
}
