PlumberResponse <- R6Class(
  "PlumberResponse",
  public = list(
    initialize = function(serializer="json"){
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

      if (is.null(h$`Access-Control-Allow-Origin`)){
        h$`Access-Control-Allow-Origin` <-  "*" # Be permissive with CORS
      }

      # Due to https://github.com/rstudio/httpuv/issues/49, we need each
      # request to be on a separate TCP stream
      h$Connection = "close"

      list(
        status = self$status,
        headers = h,
        body = self$body
      )
    },
    # TODO: support multiple setCoookies per response
    setCookie = function(name, value, path){
      # TODO: support expiration
      # TODO: support HTTP-only
      # TODO: support secure

      # Keep headers up-to-date

      self$setHeader("Set-Cookie", cookieToStr(name, value, path))
    }
  )
)

#' @importFrom utils URLencode
#' @noRd
cookieToStr <- function(name, value, path){
  val <- URLencode(as.character(value))
  str <- paste0(name, "=", val, "; ")

  if (!missing(path)){
    str <- paste0(str, "Path=", path, "; ")
  }

  # Trim last '; '
  substr(str, 0, nchar(str)-2)
}
