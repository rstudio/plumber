postBodyFilter <- function(req){

  if (!is.null(req$CONTENT_TYPE) && grepl("multipart/form-data; boundary=",
                                          req$CONTENT_TYPE, fixed = TRUE)) {

    boundary <- strsplit(req$CONTENT_TYPE, split = "=")[[1]][2]
    body <- req$rook.input$read()
    args <- parseMultipart(body, boundary)
  } else {
    body <- req$rook.input$read_lines()
    args <- parseBody(body)
  }
  req$postBody <- body
  req$args <- c(req$args, args)
  forward()
}

#' @importFrom utils URLdecode
#' @noRd
parseBody <- function(body){
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

#' @importFrom utils URLdecode
#' @noRd
parseMultipart <- function(body, boundary){
  # This is not as generic as perhaps it should be, but should be relatively
  # easy to extend if more binary formats are required
  # Is there data in the request?
  if (is.null(body) || length(body) == 0 || body == "") {
    return(list())
  }
  # This is something odd with webutils::parse_multipart. For some reason it
  # does not work when the boundary is set to the content type as per the
  # webutils docs.
  parsed_binary <- webutils::parse_multipart(body, boundary)
#  file_name = "test.feather"
  file_name <- parsed_binary$myfile$filename
  file_data <- parsed_binary$myfile$value

  tmpfile <- tempfile()
  writeBin(file_data, tmpfile)

  ret <- NULL
  ret$name <- file_name
  ret$data <- tmpfile
  ret
}
