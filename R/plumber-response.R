
PlumberResponse <- R6Class(
  "PlumberResponse",
  public = list(
    initialize = function(serializer=serializer_json()){
      self$serializer <- serializer
    },
    status = 200L,
    body = NULL,
    headers = list(),
    serializer = NULL,
    setHeader = function(name, value){
      he <- list()
      he[[name]] <- value
      self$headers <- c(self$headers, he)
    },
    toResponse = function(){
      h <- self$headers

      body <- self$body
      if (is.null(body)){
        body <- ""
      }

      charset <- getCharacterSet(h$HTTP_CONTENT_TYPE)
      if (is.character(body)) {
        Encoding(body) <- charset
      }

      list(
        status = self$status,
        headers = h,
        body = body
      )
    },
    # TODO if name and value are a vector of same length, call set cookie many times
    setCookie = function(name, value, path, expiration = FALSE, http = FALSE, secure = FALSE, sameSite=FALSE) {
      self$setHeader("Set-Cookie", cookieToStr(name, value, path, expiration, http, secure, sameSite))
    },
    removeCookie = function(name, path, http = FALSE, secure = FALSE, sameSite = FALSE, ...) {
      self$setHeader("Set-Cookie", removeCookieStr(name, path, http, secure, sameSite))
    }
  )
)

removeCookieStr <- function(name, path, http = FALSE, secure = FALSE, sameSite = FALSE) {
  str <- paste0(name, "=; ")
  if (!missing(path)){
    str <- paste0(str, "Path=", path, "; ")
  }
  if (!missing(http) && http){
    str <- paste0(str, "HttpOnly; ")
  }
  if (!missing(secure) && secure){
    str <- paste0(str, "Secure; ")
  }

  if (!missing(sameSite) && is.character(sameSite)) {
    str <- paste0(str, "SameSite=", sameSite, "; ")
  }

  str <- paste0(str, "Expires=Thu, 01 Jan 1970 00:00:00 GMT")
  str
}

#' @noRd
cookieToStr <- function(
  name,
  value,
  path,
  expiration = FALSE,
  http = FALSE,
  secure = FALSE,
  sameSite = FALSE,
  now = Sys.time() # used for testing. Should not be used in regular code.
){
  val <- httpuv::encodeURIComponent(as.character(value))
  str <- paste0(name, "=", val, "; ")

  if (!missing(path)){
    str <- paste0(str, "Path=", path, "; ")
  }

  if (!missing(http) && http){
    str <- paste0(str, "HttpOnly; ")
  }

  if (!missing(secure) && secure){
    str <- paste0(str, "Secure; ")
  }

  if (!missing(sameSite) && is.character(sameSite)) {
    str <- paste0(str, "SameSite=", sameSite, "; ")
  }

  if (!missing(expiration)){
    if (is.numeric(expiration)){
      # Number of seconds in the future
      expy <- now + expiration
      expyStr <- format(expy, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)

      str <- paste0(str, "Expires= ", expyStr, "; ")
      str <- paste0(str, "Max-Age= ", expiration, "; ")
    } else if (inherits(expiration, "POSIXt")){
      seconds <- difftime(expiration, now, units="secs")
      # TODO: DRY
      expyStr <- format(expiration, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)
      str <- paste0(str, "Expires= ", expyStr, "; ")
      str <- paste0(str, "Max-Age= ", as.integer(seconds), "; ")
    } # interpret all other values as session cookies.
  }

  # Trim last '; '
  ret <- substr(str, 0, nchar(str)-2)

  # double check size limit isn't reached
  cookieByteSize <- length(charToRaw(ret))
  # http://browsercookielimits.squawky.net/#limits
  #  typical browsers support 4096.  A couple safari based browsers max out at 4093.
  if (cookieByteSize > 4093) {
    warning(
      "Cookie being saved is too large",
      " (> 4093 bytes; found ", cookieByteSize, " bytes).",
      " Browsers may not support such a large value.\n",
      "Consider using a database and only storing minimal information.")
  }

  ret
}
