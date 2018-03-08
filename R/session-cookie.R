#' Store session data in encrypted cookies.
#' @param key The secret key to use. This must be consistent across all sessions
#'   where you want to save/restore encrypted cookies. It should be a long and
#'   complex character string to bolster security.
#' @param name The name of the cookie in the user's browser.
#' @param ... Arguments passed on to the \code{response$setCookie} call to,
#'   for instance, set the cookie's expiration.
#' @include plumber.R
#' @export
sessionCookie <- function(key, name="plumber", ...){
  if (missing(key)){
    stop("You must define an encryption key or set it to NULL to disable encryption")
  }

  if (!is.null(key)){
    key <- openssl::sha256(charToRaw(key))
  }

  # Return a list that can be added to registerHooks()
  list(
    preroute = function(req, res, data){

      cookies <- req$cookies
      if (is.null(cookies)){
        # The cookie-parser filter has probably not run yet. Parse the cookies ourselves
        # TODO: would be more performant not to run this cookie parsing twice.
        cookies <- parseCookies(req$HTTP_COOKIE)
      }
      session <- cookies[[name]]

      if (!is.null(session) && !identical(session, "")){
        if (!is.null(key)){
          tryCatch({
            session <- base64enc::base64decode(session)
            session <- openssl::aes_cbc_decrypt(session, key)
            session <- rawToChar(session)

            session <- jsonlite::fromJSON(session)
          }, error=function(e){
            warning("Error processing session cookie. Perhaps your secret changed?")
            session <<- NULL
          })
        }
      }
      req$session <- session
    },
    postroute = function(value, req, res, data){
      if (!is.null(req$session)){
        sess <- jsonlite::toJSON(req$session)
        if (!is.null(key)){
          sess <- openssl::aes_cbc_encrypt(charToRaw(sess), key, iv = NULL)
          sess <- base64enc::base64encode(sess)
        }
        res$setCookie(name, sess, ...)
      }
      value
    }
  )
}
