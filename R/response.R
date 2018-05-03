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
      # httpuv doesn't like empty headers lists, and this is a useful field anyway...
      h$Date <- format(Sys.time(), "%a, %d %b %Y %X %Z", tz="GMT")

      # Due to https://github.com/rstudio/httpuv/issues/49, we need each
      # request to be on a separate TCP stream
      h$Connection = "close"

      body <- self$body
      if (is.null(body)){
        body <- ""
      }
      Encoding(body) <- "UTF-8"
      list(
        status = self$status,
        headers = h,
        body = body
      )
    },
    # TODO: support multiple setCookies per response
    setCookie = function(name, value, path, expiration=FALSE, http=FALSE, secure=FALSE){
      self$setHeader("Set-Cookie", cookieToStr(name, value, path, expiration, http, secure))
    }
  )
)

#' @importFrom utils URLencode
#' @noRd
cookieToStr <- function(name, value, path, expiration=FALSE, http=FALSE, secure=FALSE){
  val <- URLencode(as.character(value))
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

  if (!missing(expiration)){
    if (is.numeric(expiration)){
      # Number of seconds in the future
      now <- Sys.time()
      expy <- now + expiration
      expyStr <- format(expy, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)

      str <- paste0(str, "Expires= ", expyStr, "; ")
      str <- paste0(str, "Max-Age= ", expiration, "; ")
    } else if (inherits(expiration, "POSIXt")){
      seconds <- difftime(expiration, Sys.time(), units="secs")
      # TODO: DRY
      expyStr <- format(expiration, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)
      str <- paste0(str, "Expires= ", expyStr, "; ")
      str <- paste0(str, "Max-Age= ", as.integer(seconds), "; ")
    } # interpret all other values as session cookies.
  }

  # Trim last '; '
  substr(str, 0, nchar(str)-2)
}
