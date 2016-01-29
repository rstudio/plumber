#' @include processor.R
#' @include plumber.R
#' @export
sessionCookie <- function(name="plumber"){
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
        # TODO: try-catch
        session <- jsonlite::fromJSON(session)
      }
      req$session <- session
      print("PRE -- setting cookie to :")
      print(req$session)
    },
    post=function(value, req, res, data){
      print("POST")
      print(req$session)
      if (!is.null(req$session)){
        sess <- jsonlite::toJSON(req$session)
        res$setCookie(name, sess)
      }
      value
    }
  )
}
