
make_req <- function(verb = "GET", path = "/", qs="", body="", args = c(), pr = NULL, ...){
  req <- as.environment(list(...))
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$QUERY_STRING <- qs

  if (is.character(body)) {
    body <- charToRaw(body)
  }
  stopifnot(is.raw(body))
  req$rook.input <- list(read_lines = function(){ rawToChar(body) },
                         read = function(){ body },
                         rewind = function(){ length(body) })
  req$bodyRaw <- body
  req$pr <- pr
  req
}
