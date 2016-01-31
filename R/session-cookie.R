#' @include processor.R
#' @include plumber.R
#' @importFrom PKI PKI.encrypt
#' @importFrom PKI PKI.decrypt
#' @importFrom PKI PKI.digest
#' @importFrom base64enc base64encode
#' @importFrom base64enc base64decode
#' @export
sessionCookie <- function(key, name="plumber"){
  if (missing(key)){
    stop("You must define an encryption key or set it to NULL to disable encryption")
  }

  if (!is.null(key)){
    checkPKI()
    key <- PKI.digest(charToRaw(key), "SHA256")
  }

  list( #TODO: should be a Processor
    pre=function(req, res, data){
      cookie <- req$HTTP_COOKIE
      if (is.null(cookie) || nchar(cookie) == 0){
        req$cookies <- NULL
        req$session <- NULL
        return()
      }

      cookie <- strsplit(cookie, ";", fixed=TRUE)[[1]]
      cookie <- sub("\\s*([\\S*])\\s*", "\\1", cookie, perl=TRUE)

      cookieList <- strsplit(cookie, "=", fixed=TRUE)
      cookies <- lapply(cookieList, "[[", 2)
      names(cookies) <- sapply(cookieList, "[[", 1)

      req$cookies <- cookies

      session <- cookies[[name]]

      if (!is.null(session) && !identical(session, "")){
        if (!is.null(key)){
          # TODO: try-catch this
          session <- base64decode(session)
          session <- PKI.decrypt(session, key, "aes256")
          session <- rawToChar(session)
        }

        # TODO: try-catch
        session <- jsonlite::fromJSON(session)
      }
      req$session <- session
    },
    post=function(value, req, res, data){
      if (!is.null(req$session)){
        sess <- jsonlite::toJSON(req$session)
        if (!is.null(key)){
          sess <- PKI.encrypt(charToRaw(sess), key, "aes256")
          sess <- base64encode(sess)
        }
        res$setCookie(name, sess)
      }
      value
    }
  )
}

checkPKI <- function(){
  pkiVer <- tryCatch({as.character(packageVersion("PKI"))},
                     error=function(e){"0.0.0"});
  if (compareVersion(pkiVer, "0.1.2") < 0){
    stop("You need PKI version 0.1.2 or greater installed.")
  }
}
