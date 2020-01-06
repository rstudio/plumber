postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE){
    body <- paste0(req$rook.input$read_lines(), collapse = "\n")
    charset <- getCharacterSet(req$HTTP_CONTENT_TYPE)
    args <- parseBody(body, charset)
    req$postBody <- body
    req$args <- c(req$args, args)
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

#' @noRd
parseBody <- function(body, charset = "UTF-8"){
  # The body in a curl call can also include querystring formatted data
  # Is there data in the request?
  if (is.null(body) || length(body) == 0 || body == "" || charset == "bytes") {
    return(list())
  }

  if (is.character(body)) {
    Encoding(body) <- charset
  }

  # Is it JSON data?
  if (stri_startswith_fixed(body, "{")) {
    ret <- safeFromJSON(body)
  } else {
    # If not handle it as a query string
    ret <- parseQS(body)
  }
  ret
}
