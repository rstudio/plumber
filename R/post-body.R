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

# use something similar to opencpu parse_post
#' @noRd
#' @importFrom webutils parse_multipart
parseBody <- function(body, content_type = "unknown") {
  # The body in a curl call can also include querystring formatted data
  # Is there data in the request?
  if (is.null(body) || length(body) == 0 || body == "") {
    return(list())
  }
  if (!is.raw(body)) body <- charToRaw(body)
  if (is.null(content_type) || length(content_type) == 0 ||
      content_type == "" || !stri_detect_fixed(content_type, "multipart/form-data")) {
    toparse <- list(list(value = body, content_type = content_type))
  } else {
    if (!stri_detect_fixed(content_type, "boundary=", case_insensitive = TRUE))
      stop("No boundary found in multipart content-type header: ", content_type)
    boundary <- stri_match_first(content_type, regex = "boundary=([^; ]{2,})", case_insensitive = TRUE)[,2]
    toparse <- webutils::parse_multipart(body, boundary)
  }
  do.call(c, lapply(toparse, parseRaw))
}

parseRaw <- function(toparse) {
  if (!is.null(toparse$filename)) {
    ext <- tools::file_ext(toparse$filename)
    toparse$content_type <- getContentType(ext)
  }
  parser <- parserPicker(toparse$content_type)
  if (length(parser) == 0L) {
    if (toparse$value[1] %in% charToRaw("[{")) {
      parser <- .globals$parsers[["json"]]
    } else {
      parser <- .globals$parsers[["query"]]
    }
  } else {
    parser <- parser[[1L]]
  }
  do.call(parser(), toparse)
}

parserPicker <- function(content_type) {
  regexes <- vapply(.globals$parsers, attr, character(1), "regex")
  parser <- .globals$parsers[stri_detect_regex(content_type, paste0("^", regexes), case_insensitive = TRUE)]
  if (length(parser) > 1L) {
    parser <- parser[1L]
    # Should we warn?
    # warning("Multiple body parsers matches for content-type : ", toparse$content_type, ". Parser ", names(parser)[1L], " used.")
  }
  parser
}
