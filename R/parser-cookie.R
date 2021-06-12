cookieFilter <- function(req){
  cookie <- req$HTTP_COOKIE
  req$cookies <- parseCookies(cookie)
  forward()
}

#' @noRd
parseCookies <- function(cookie) {
  if (is.null(cookie) || nchar(cookie) == 0) {
    return(list())
  }
  cookie <- strsplit(cookie, ";", fixed=TRUE)[[1]]
  cookie <- sub("\\s*([\\S*])\\s*", "\\1", cookie, perl=TRUE)

  cookieList <- stri_split_fixed(str = cookie, pattern = "=", n = 2)

  # Handle any non-existent cookie values.
  for (i in seq_along(cookieList)) {
    if(length(cookieList[[i]]) == 1) {
      cookieList[[i]][[2]] <- ""
    }
  }

  cookies <- vapply(cookieList, "[[", character(1), 2)
  decodedCookies <- as.list(httpuv::decodeURIComponent(cookies))
  cookieNames <- vapply(cookieList, "[[", character(1), 1)
  names(decodedCookies) <- cookieNames
  decodedCookies
}
