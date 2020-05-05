postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE) {
    body <- req$rook.input$read()
    type <- req$HTTP_CONTENT_TYPE
    args <- parseBody(body, type)
    req$postBody <- body #this is a raw body contrary to what plumber did before
    req$args <- c(req$args, args)
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

parseBody <- function(body, content_type = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  if (length(body) == 0L) return(list())
  toparse <- list(value = body, content_type = content_type)
  parseRaw(toparse)
}

parseRaw <- function(toparse) {
  parser <- parserPicker(toparse$content_type, toparse$value[1], toparse$filename)
  do.call(parser(), toparse)
}

parserPicker <- function(content_type, first_byte, filename = NULL) {
  #fast default to json when first byte is 7b ({)
  if (first_byte == as.raw(123L))
    return(.globals$parsers$f[["json"]])
  if (is.null(content_type)) {
    return(.globals$parsers$f[["query"]])
  }
  # then try to find a match
  patterns <- .globals$parsers$p
  parser <- .globals$parsers$f[stri_startswith_fixed(content_type, patterns)]
  # Should we warn when multiple parsers match?
  # warning("Multiple body parsers matches for content-type : ", toparse$content_type, ". Parser ", names(parser)[1L], " used.")
  if (length(parser) == 0L) {
    if (is.null(filename)) {
      return(.globals$parsers$f[["query"]])
    } else {
      return(.globals$parsers$f[["octet"]])
    }
  } else {
    return(parser[[1L]])
  }
}
