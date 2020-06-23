postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE) {
    # This will return raw bytes
    body <- req$rook.input$read()
    type <- req$HTTP_CONTENT_TYPE
    args <- parseBody(body, type)
    req$args <- c(req$args, args)
    req$postBodyRaw <- body
    if (isTRUE(getOption("plumber.postBody", TRUE))) {
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
  if (first_byte == as.raw(123L)) {
    return(.globals$parsers$func[["json"]])
  }
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



#' Plumber Parsers
#'
#' Parsers are used in Plumber to transform the raw body content received
#' by a request to the API.
#' @name parsers
#' @rdname parsers
NULL

#' Add a Parsers
#'
#' A parser is responsible for decoding the raw body content of a request into
#' a list of arguments that can be mapped to endpoint function arguments.
#' For instance, the \code{parser_json} parser content-type `application/json`.
#' The list of available parsers in plumber is global.
#'
#' @param name The name of the parser (character string)
#' @param parser The parser to be added.
#' @param pattern A pattern to match against the content-type of each part of
#' the request body.
#'
#' @details For instance, the \code{parser_json} pattern is `application/json`.
#' If `pattern` is not provided, will be set to `application/{name}`.
#' Detection is done assuming content-type starts with pattern and is
#' case sensitive.
#'
#' Parser function structure is something like below. Available parameters
#' to build parser are `value`, `content_type` and `filename` (only available
#' in `multipart-form` body).
#' ```r
#' parser <- function() {
#'   function(value, content_type = "ct", filename, ...) {
#'     # do something with raw value
#'   }
#' }
#' ```
#'
#' It should return a named list if you want values to map to
#' plumber endpoint function args.
#'
#' @examples
#' parser_json <- function() {
#'   function(value, content_type = "application/json", ...) {
#'     charset <- getCharacterSet(content_type)
#'     value <- rawToChar(value)
#'     Encoding(value) <- charset
#'     jsonlite::fromJSON(value)
#'   }
#' }
#' @md
#' @export
addParser <- function(name, parser, pattern = NULL) {
  if (is.null(.globals$parsers)) {
    .globals$parsers <- list()
  }
  if (!is.null(.globals$parsers$func[[name]])) {
    stop("Already have a parser by the name of ", name)
  }
  if (is.null(pattern)) {
    pattern <- paste0("application/", name)
  }
  .globals$parsers$func[[name]] <- parser
  .globals$parsers$pattern[[name]] <- pattern
}



#' JSON
#' @rdname parsers
#' @export
parser_json <- function() {
  function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    safeFromJSON(value)
  }
}




#' QUERY STRING
#' @rdname parsers
#' @export
parser_query <- function() {
  function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    parseQS(value)
  }
}




#' TEXT
#' @rdname parsers
#' @export
parser_text <- function() {
  function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    value
  }
}




#" RDS
#' @rdname parsers
#' @export
parser_rds <- function() {
  function(value, filename, ...) {
    tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
    on.exit(file.remove(tmp), add = TRUE)
    writeBin(value, tmp)
    readRDS(tmp)
  }
}




#" MULTI
#' @rdname parsers
#' @export
#' @importFrom webutils parse_multipart
parser_multi <- function() {
  function(value, content_type, ...) {
    if (!stri_detect_fixed(content_type, "boundary=", case_insensitive = TRUE))
      stop("No boundary found in multipart content-type header: ", content_type)
    boundary <- stri_match_first_regex(content_type, "boundary=([^; ]{2,})", case_insensitive = TRUE)[,2]
    toparse <- parse_multipart(value, boundary)
    # content-type detection
    lapply(toparse, function(x) {
      if (!is.null(x$filename)) {
        x$content_type <- getContentType(tools::file_ext(x$filename))
      }
      parseRaw(x)
    })
  }
}




#' OCTET
#' @rdname parsers
#' @export
parser_octet <- function() {
  function(value, filename = NULL, ...) {
    attr(value, "filename") <- filename
    return(value)
  }
}




#' YAML
#' @rdname parsers
#' @export
parser_yaml <- function() {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("yaml must be installed for the yaml parser to work")
  }
  function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    yaml::yaml.load(value)
  }
}




addParsers_onLoad <- function() {
  addParser("json", parser_json, "application/json")
  addParser("query", parser_query, "application/x-www-form-urlencoded")
  addParser("text", parser_text, "text/")
  addParser("rds", parser_rds, "application/rds")
  addParser("multi", parser_multi, "multipart/form-data")
  addParser("octet", parser_octet, "application/octet")
  addParser("yaml", parser_yaml, "application/x-yaml")
}
