#' HTTP Date String
#'
#' Given a POSIXct object, return a date string in the format required for a
#' HTTP Date header. For example: "Wed, 21 Oct 2015 07:28:00 GMT"
#'
#' @noRd
http_date_string <- function(time) {
  weekday_names <- c("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
  weekday_num <- as.integer(strftime(time, format = "%w", tz = "GMT")) + 1L
  weekday_name <- weekday_names[weekday_num]

  month_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  month_num <- as.integer(strftime(time, format = "%m", tz = "GMT"))
  month_name <- month_names[month_num]

  strftime(
    time,
    paste0(weekday_name, ", %d ", month_name, " %Y %H:%M:%S GMT"),
    tz = "GMT"
  )
}

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
      h$Date <- http_date_string(Sys.time())

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
