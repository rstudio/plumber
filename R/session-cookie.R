#' Store session data in encrypted cookies.
#' @param key The secret key to use. This must be consistent across all sessions
#'   where you want to save/restore encrypted cookies. It should be a long and
#'   complex character string to bolster security.
#' @param name The name of the cookie in the user's browser.
#' @param ... Arguments passed on to the \code{response$setCookie} call to,
#'   for instance, set the cookie's expiration.
#' @include processor.R
#' @include plumber.R
#' @export
sessionCookie <- function(key, name="plumber", ...){
  if (missing(key)){
    stop("You must define an encryption key or set it to NULL to disable encryption")
  }

  if (!is.null(key)){
    checkPKI()
    key <- PKI::PKI.digest(charToRaw(key), "SHA256")
  }

  PlumberProcessor$new(
    "sessionCookie",
    pre=function(req, res, data){

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
            session <- PKI::PKI.decrypt(session, key, "aes256")
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
    post=function(value, req, res, data){
      if (!is.null(req$session)){
        sess <- jsonlite::toJSON(req$session)
        if (!is.null(key)){
          sess <- PKI::PKI.encrypt(charToRaw(sess), key, "aes256")
          sess <- base64enc::base64encode(sess)
        }
        res$setCookie(name, sess, ...)
      }
      value
    }
  )
}

#' @importFrom utils packageVersion
#' @importFrom utils compareVersion
#' @noRd
checkPKI <- function(){
  pkiVer <- tryCatch({as.character(packageVersion("PKI"))},
                     error=function(e){"0.0.0"});
  if (compareVersion(pkiVer, "0.1.2") < 0){
    stop("You need PKI version 0.1.2 or greater installed.")
  }
}
