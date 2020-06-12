postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE) {
    # This will return raw bytes
    body <- req$rook.input$read()
    type <- req$HTTP_CONTENT_TYPE
    args <- parseBody(body, type)
    req$args <- c(req$args, args)
    req$postBodyRaw <- body
    if (getOption("plumber.postBody", TRUE)) {
      req$rook.input$rewind()
      req$postBody <- paste0(req$rook.input$read_lines(), collapse = "\n")
    }
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

parseBody <- function(body, content_type = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  toparse <- list(value = body, content_type = content_type)
  parseRaw(toparse)
}

parseRaw <- function(toparse) {
  if (length(toparse$value) == 0L) return(list())
  parser <- parserPicker(toparse$content_type, toparse$value[1], toparse$filename)
  do.call(parser(), toparse)
}

parserPicker <- function(content_type, first_byte, filename = NULL) {
  #fast default to json when first byte is 7b (ascii {)
  if (first_byte == as.raw(123L))
    return(.globals$parsers$func[["json"]])
  if (is.null(content_type)) {
    return(.globals$parsers$func[["query"]])
  }
  # else try to find a match
  patterns <- .globals$parsers$pattern
  parser <- .globals$parsers$func[stri_startswith_fixed(content_type, patterns)]
  # Should we warn when multiple parsers match?
  # warning("Multiple body parsers matches for content-type : ", toparse$content_type, ". Parser ", names(parser)[1L], " used.")
  if (length(parser) == 0L) {
    if (is.null(filename)) {
      return(.globals$parsers$func[["query"]])
    } else {
      return(.globals$parsers$func[["octet"]])
    }
  } else {
    return(parser[[1L]])
  }
}
