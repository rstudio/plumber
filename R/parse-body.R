postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE) {
    # This will return raw bytes
    body <- req$rook.input$read()
    type <- req$HTTP_CONTENT_TYPE
    args <- parse_body(body, type)
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

parse_body <- function(body, content_type = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  toparse <- list(value = body, content_type = content_type)
  parse_raw(toparse)
}

parse_raw <- function(toparse) {
  if (length(toparse$value) == 0L) return(list())
  parser <- parser_picker(toparse$content_type, toparse$value[1], toparse$filename)
  do.call(parser, toparse)
}

parser_picker <- function(content_type, first_byte, filename = NULL) {
  parsers <- .globals$parsers

  # parse as a query string
  if (is.null(content_type)) {
    # fast default to json when first byte is 7b (ascii {)
    if (first_byte == as.raw(123L)) {
      return(parsers$json)
    }

    return(parsers$query)
  }

  # remove trailing content type information
  # "application/json; charset=UTF-8"
  # to
  # "application/json"
  if (grepl(";", content_type, fixed = TRUE)) {
    content_type <- strsplit(content_type, ";")[[1]][1]
  }

  parser <- parsers[[content_type]]

  # return known parser
  if (!is.null(parser)) {
    return(parser)
  }

  # return text parser
  if (stri_startswith_fixed(content_type, "text/")) {
    # text parser
    return(parsers$text)
  }

  # query string
  if (is.null(filename)) {
    return(parsers$query)
  }

  # octect
  parsers$octet
}


#' Add a Parsers
#'
#' A parser is responsible for decoding the raw body content of a request into
#' a list of arguments that can be mapped to endpoint function arguments.
#' For instance, the \code{parser_json} parser content-type `application/json`.
#'
#' @param content_type A string to match against the content-type of each part of
#' the request body
#' @param parser The parser function to be added. This function should possibly
#'   accept `value` and the named parameters `content_type` and `filename`.
#'   Other parameters may be provided from [webutils::parse_multipart()].
#'   To be safe, add a `...` to your function signature.
#' @param verbose Logical value which determines if a warning should be
#'   displayed when patterns are overwritten.
#'
#' @details
#'
#' Parser function structure is something like below. Available parameters
#' to build parser are `value`, `content_type` and `filename` (only available
#' in `multipart-form` body).
#' ```r
#' parser <- function(value, content_type = "ct", filename, ...) {
#'   # do something with raw value
#' }
#' ```
#'
#' It should return a named list if you want values to map to
#' plumber endpoint function args.
#'
#' @examples
#' parser_dcf <- function(value, content_type = "text/x-dcf", ...) {
#'   charset <- getCharacterSet(content_type)
#'   value <- rawToChar(value)
#'   Encoding(value) <- charset
#'   read.dcf(value)
#' }
#' @export
add_parser <- function(content_type, parser, verbose = TRUE) {

  if (!is.null(.globals$parsers[[content_type]])) {
    if (isTRUE(verbose)) {
      warning("Overwriting parser: ", content_type)
    }
  }

  stopifnot(is.function(parser))

  .globals$parsers[[content_type]] <- parser

  invisible(.globals$parsers)
}


#' Plumber Parsers
#'
#' Parsers are used in Plumber to transform the raw body content received
#' by a request to the API. Extra parameters may be provided to parser
#' functions when adding the parser to plumber. This will allow for
#' non-default behavior.
#'
#' @param ... parameters supplied to the appropriate internal function
#' @describeIn parsers Query string parser
#' @examples
#' \dontrun{
#' # Overwrite `text/json` parsing behavior to not allow JSON vectors to be simplified
#' add_parser("text/json", parser_json(simplifyVector = FALSE))
#' }
#' @export
parser_query <- function() {
  parser_text(parseQS)
}


#' @describeIn parsers JSON parser
#' @export
parser_json <- function(...) {
  parser_text(function(value) {
    safeFromJSON(value, ...)
  })
}


#' @describeIn parsers Helper parser to parse plain text
#' @param parse_fn function to further decode a text string into an object
#' @export
parser_text <- function(parse_fn = identity) {
  stopifnot(is.function(parse_fn))
  function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    parse_fn(value)
  }
}


#' @describeIn parsers CSV parser
#' @export
parser_csv <- function(...) {
  parser_text(function(val) {
    utils::read.csv(val, ...)
  })
}


#' @describeIn parsers TSV parser
#' @export
parser_tsv <- function(...) {
  parser_text(function(val) {
    utils::read.delim(val, ...)
  })
}


#' @describeIn parsers YAML parser
#' @export
parser_yaml <- function(...) {
  parser_text(function(val) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("yaml must be installed for the yaml parser to work")
    }
    yaml::yaml.load(val, ...)
  })
}

#' @describeIn parsers Helper parser that writes the binary post body to a file and reads it back again using `read_fn`.
#'   This parser should be used when reading from a file is required.
#' @param read_fn function used to read a the content of a file. Ex: [readRDS()]
#' @export
parser_read_file <- function(read_fn = readLines) {
  stopifnot(is.function(read_fn))
  function(value, filename, ...) {
    tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
    on.exit({
      file.remove(tmp)
    }, add = TRUE)
    writeBin(value, tmp)
    read_fn(tmp)
  }
}

#' @describeIn parsers RDS parser
#' @export
parser_rds <- function(...) {
  parser_read_file(function(value) {
    readRDS(value, ...)
  })
}




#' @describeIn parsers Octet stream parser
#' @export
parser_octet <- function() {
  function(value, filename = NULL, ...) {
    attr(value, "filename") <- filename
    value
  }
}


#' @describeIn parsers Multi part parser. This parser will then parse each individual body with its respective parser
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
      if (is.null(x$content_type) || isTRUE(x$content_type == "application/octet-stream")) {
        if (!is.null(x$filename)) {
          # Guess content-type from file extension
          x$content_type <- getContentType(tools::file_ext(x$filename))
        }
      }
      parse_raw(x)
    })
  }
}



add_parsers_onLoad <- function() {

  # add both `application/XYZ` and `text/XYZ` parsers
  for (type in c("application", "text")) {
    mime_type <- function(x) {
      paste0(type, "/", x)
    }

    add_parser(mime_type("json"),                 parser_json())

    add_parser(mime_type("csv"),                  parser_csv())
    add_parser(mime_type("x-csv"),                parser_csv())

    add_parser(mime_type("yaml"),                 parser_yaml())
    add_parser(mime_type("x-yaml"),               parser_yaml())

    add_parser(mime_type("tab-separated-values"), parser_tsv())

  }

  # only one form of these parsers
  add_parser("application/x-www-form-urlencoded", parser_query())
  add_parser("application/rds",                   parser_rds())
  add_parser("multipart/form-data",               parser_multi())
  add_parser("application/octet",                 parser_octet())

  add_parser("text/plain", parser_text())


  # shorthand names for parser_picker
  add_parser("text", parser_text())
  add_parser("query", parser_query())
  add_parser("octet", parser_octet())
  add_parser("json", parser_json())
}
