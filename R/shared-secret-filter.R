#' @noRd
sharedSecretFilter <- function(req, res){
  secret <- get_option_or_env("plumber.sharedSecret", NULL)
  if (!is.null(secret)){
    supplied <- req$HTTP_PLUMBER_SHARED_SECRET
    if (!identical(supplied, secret)){
      # Don't overly leak data unless they opt-in
      msg <- if (req$pr$getDebug()) "Shared secret mismatch"

      return(http_problem_response(req, res, bad_request(msg)))
    }
  }

  forward()
}
