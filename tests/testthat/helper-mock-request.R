
make_req <- function(verb, path, qs="", body=""){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$QUERY_STRING <- qs
  req$rook.input <- list(read_lines = function(){ body })
  req
}
