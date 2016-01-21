#' @include processor.R
#' @include plumber.R
sessionCookie <- function(name="plumber"){
  PlumberProcessor$new(
    name="sessionCookie",
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

      req$session <- cookies[[name]]
    },
    post=function(value, req, res, data){
      print(req$session)
      if (!is.null(req$session)){
        sess <- jsonlite::toJSON(req$session)
        res$setCookie(name, sess)
      }
      value
    }
  )
}
