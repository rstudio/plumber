postBodyFilter <- function(req){
  handled <- req$.internal$postBodyHandled
  if (is.null(handled) || handled != TRUE) {
    # This will return raw bytes
    req$postBodyRaw <- req$rook.input$read()
    if (isTRUE(getOption("plumber.postBody", TRUE))) {
      req$rook.input$rewind()
      req$postBody <- paste0(req$rook.input$read_lines(), collapse = "\n")
    }
    req$.internal$postBodyHandled <- TRUE
  }
  forward()
}

postbody_parser <- function(req, parsers = NULL) {
  type <- req$HTTP_CONTENT_TYPE
  body <- req$postBodyRaw
  if (length(body)>1) {
    parse_body(body, type, parsers)
  } else {
    list()
  }
}

parse_body <- function(body, content_type = NULL, parsers = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  toparse <- list(value = body, content_type = content_type, parsers = parsers)
  parse_raw(toparse)
}

parse_raw <- function(toparse) {
  if (length(toparse$value) == 0L) return(list())
  parser <- parser_picker(toparse$content_type, toparse$value[1], toparse$filename, toparse$parsers)
  if (!is.null(parser)) {
   return(do.call(parser, toparse))
  } else {
    warning("No suitable parser found to handle request body type ", toparse$content_type, ".")
    return(list())
  }
}

parser_picker <- function(content_type, first_byte, filename = NULL, parsers = NULL) {

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
  if (stri_detect_fixed(content_type, ";")) {
    content_type <- stri_split_fixed(content_type, ";")[[1]][1]
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

  # octet
  parsers$octet
}


#' Add a Parsers
#'
#' A parser is responsible for decoding the raw body content of a request into
#' a list of arguments that can be mapped to endpoint function arguments.
#' For instance, the \code{parser_json} parser content-type `application/json`.
#'
#' @param alias Short name to map parser
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
add_parser <- function(alias, parser, verbose = TRUE) {

  if (!is.null(.globals$parsers[[alias]])) {
    if (isTRUE(verbose)) {
      warning("Overwriting parser: ", alias)
    }
  }

  stopifnot(is.function(parser))

  .globals$parsers[[alias]] <- parser

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
  parse_func <- parser_text(parseQS)[[1]]
  return(invisible(
    list("application/x-www-form-urlencoded" = parse_func,
         "query" = parse_func)
  ))
}


#' @describeIn parsers JSON parser
#' @export
parser_json <- function(...) {
  parse_func <- parser_text(function(value) {
    safeFromJSON(value, ...)
  })[[1]]
  return(invisible(
    list("application/json" = parse_func,
         "text/json" = parse_func,
         "json" = parse_func)
  ))
}


#' @describeIn parsers Helper parser to parse plain text
#' @param parse_fn function to further decode a text string into an object
#' @export
parser_text <- function(parse_fn = identity) {
  stopifnot(is.function(parse_fn))
  parse_func <- function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    parse_fn(value)
  }
  return(invisible(
    list("text/plain" = parse_func,
         "text" = parse_func)
  ))
}


#' @describeIn parsers YAML parser
#' @export
parser_yaml <- function(...) {
  parse_func <- parser_text(function(val) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("yaml must be installed for the yaml parser to work")
    }
    yaml::yaml.load(val, ...)
  })[[1]]
  return(invisible(
    list("application/yaml" = parse_func,
         "application/x-yaml" = parse_func,
         "text/yaml" = parse_func,
         "text/x-yaml" = parse_func)
  ))
}

#' @describeIn parsers Helper parser that writes the binary post body to a file and reads it back again using `read_fn`.
#'   This parser should be used when reading from a file is required.
#' @param read_fn function used to read a the content of a file. Ex: [readRDS()]
#' @export
parser_read_file <- function(read_fn = readLines) {
  stopifnot(is.function(read_fn))
  function(value, filename = "", ...) {
    tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
    on.exit({
      file.remove(tmp)
    }, add = TRUE)
    writeBin(value, tmp)
    read_fn(tmp)
  }
}

#' @describeIn parsers CSV parser
#' @export
parser_csv <- function(...) {
  parse_func <- parser_read_file(function(val) {
    utils::read.csv(val, ...)
  })
  return(invisible(
    list("application/csv" = parse_func,
         "application/x-csv" = parse_func,
         "text/csv" = parse_func,
         "text/x-csv" = parse_func)
  ))
}


#' @describeIn parsers TSV parser
#' @export
parser_tsv <- function(...) {
  parse_func <- parser_read_file(function(val) {
    utils::read.delim(val, ...)
  })
  return(invisible(
    list("application/tab-separated-values" = parse_func,
         "text/tab-separated-values" = parse_func)
  ))
}


#' @describeIn parsers RDS parser
#' @export
parser_rds <- function(...) {
  parse_func <- parser_read_file(function(value) {
    readRDS(value, ...)
  })
  return(invisible(
    list("application/rds" = parse_func)
  ))
}


#' @describeIn parsers Octet stream parser
#' @export
parser_octet <- function() {
  parse_func <- function(value, filename = NULL, ...) {
    attr(value, "filename") <- filename
    value
  }
  return(invisible(
    list("application/octet-stream" = parse_func,
         "octet" = parse_func)
  ))
}


#' @describeIn parsers Multi part parser. This parser will then parse each individual body with its respective parser
#' @export
#' @importFrom webutils parse_multipart
parser_multi <- function() {
  parse_func <- function(value, content_type, parsers, ...) {
    if (!stri_detect_fixed(content_type, "boundary=", case_insensitive = TRUE))
      stop("No boundary found in multipart content-type header: ", content_type)
    boundary <- stri_match_first_regex(content_type, "boundary=([^; ]{2,})", case_insensitive = TRUE)[,2]
    toparse <- parse_multipart(value, boundary)
    # content-type detection
    lapply(toparse, function(x) {
      if (
        is.null(x$content_type) ||
        # allows for files to be shipped as octect, but parsed using the matching value in `knownContentTypes`
        # (Ex: `.rds` files -> `application/rds` which has a proper RDS parser)
        isTRUE(stri_detect_fixed(x$content_type, "application/octet-stream"))
      ) {
        if (!is.null(x$filename)) {
          # Guess content-type from file extension
          x$content_type <- getContentType(tools::file_ext(x$filename))
        }
      }
      x$parsers <- parsers
      parse_raw(x)
    })
  }
  return(invisible(
    list("multipart/form-data" = parse_func)
  ))
}



add_parsers_onLoad <- function() {

  # shorthand names for parser plumbing
  add_parser("csv", parser_csv)
  add_parser("json", parser_json)
  add_parser("multi", parser_multi)
  add_parser("octet", parser_octet)
  add_parser("query", parser_query)
  add_parser("rds", parser_rds)
  add_parser("text", parser_text)
  add_parser("tsv", parser_tsv)
  add_parser("yaml", parser_yaml)
}
