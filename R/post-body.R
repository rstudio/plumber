postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE){
    body <- req$rook.input$read_lines()
    args <- parseBody(body)
    req$postBody <- body
    req$args <- c(req$args, args)
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

#' @importFrom utils URLdecode
#' @noRd
parseBody <- function(body){
  Encoding(body) <- "UTF-8"
  # The body in a curl call can also include querystring formatted data
  # Is there data in the request?
  if (is.null(body) || length(body) == 0 || body == "") {
    return(list())
  }
  # Is it JSON data?
  if (stri_startswith_fixed(body, "{")) {
    # Handle JSON with jsonlite
    ret <- jsonlite::fromJSON(body)
  } else {
    # If not handle it as a query string
      ret <- parseQS(body)
  }
  ret
}
