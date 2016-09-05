postBodyFilter <- function(req){
  body <- req$rook.input$read_lines()
  args <- parseBody(body)
  req$postBody <- body
  req$args <- c(req$args, args)
  forward()
}

#' @importFrom utils URLdecode
#' @noRd
parseBody <- function(body){
    ret <- jsonlite::fromJSON(body)
    ret
}
