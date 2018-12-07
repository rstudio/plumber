cookieFilter <- function(req){
  cookie <- req$HTTP_COOKIE
  req$cookies <- parseCookies(cookie)
  forward()
}

#' @importFrom httpuv decodeURI
#' @noRd
parseCookies <- function(cookie){
  if (is.null(cookie) || nchar(cookie) == 0){
    return(list())
  }
  cookie <- strsplit(cookie, ";", fixed=TRUE)[[1]]
  cookie <- sub("\\s*([\\S*])\\s*", "\\1", cookie, perl=TRUE)

  cookieList <- strsplit(cookie, "=", fixed=TRUE)

  # Handle any non-existent cookie values.
  for (i in 1:length(cookieList)){
    if(length(cookieList[[i]])==1){
      cookieList[[i]][[2]] <- ""
    }
  }

  cookies <- lapply(cookieList, "[[", 2)
  names(cookies) <- sapply(cookieList, "[[", 1)

  return(lapply(cookies, decodeURI))
}
