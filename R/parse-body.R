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
  if (length(parsers) == 0) {return(list())}
  type <- req$HTTP_CONTENT_TYPE
  body <- req$postBodyRaw
  if (is.null(body)) {return(list())}
  parse_body(body, type, parsers)
}

parse_body <- function(body, content_type = NULL, parsers = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  toparse <- list(value = body, content_type = content_type, parsers = parsers)
  parse_raw(toparse)
}

parse_raw <- function(toparse) {
  if (length(toparse$value) == 0L) return(list())
  parser <- parser_picker(
    # Lower case content_type for parser matching
    tolower(toparse$content_type),
    toparse$value[1],
    toparse$filename,
    toparse$parsers)
  if (!is.null(parser)) {
   return(do.call(parser, toparse))
  } else {
    message("No suitable parser found to handle request body type ", toparse$content_type, ".")
    return(list())
  }
}

parser_picker <- function(content_type, first_byte, filename = NULL, parsers = NULL) {

  # parse as a query string
  if (length(content_type) == 0) {
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

  parser <- parsers$fixed[[content_type]]

  # return known parser (exact match)
  if (!is.null(parser)) {
    return(parser)
  }

  fpm <- stri_detect_regex(
    content_type,
    names(parsers$regex),
    max_count = 1)
  fpm[is.na(fpm)] <- FALSE

  # return known parser (first regex pattern match)
  if (any(fpm)) {
    return(parsers$regex[[which(fpm)]])
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
#' For instance, \code{parser_json} parse content-type `application/json`.
#'
#' @param alias Short name to map parser from the `@parser` plumber tag.
#' @param parser The parser function to be added. This build the parser function.
#' @param verbose Logical value which determines if a warning should be
#'   displayed when alias in map are overwritten.
#'
#' @details
#' When `parser` is evaluated, it should return a named list of functions.
#' Content-types/Mime-types are used as the list names and will be matched to
#' corresponding parsing function.
#' Functions signature in the list should include `value`, `...` and
#' possibly `content_type`, `filename`. Other parameters may be provided
#' if you want to use the headers from [webutils::parse_multipart()].
#' Parser function structure is something like below.
#' ```r
#' parser <- () {
#'  f <- function(value, ...) {
#'   # do something with raw value
#'  }
#'  make_parsers(f, fixed = "ct")
#' }
#' ```
#'
#' @examples
#' # Content-type header is mostly used to look up charset and adjust encoding
#' parser_dcf <- function() {
#'   f <- function(value, content_type = "text/x-dcf", ...) {
#'     charset <- getCharacterSet(content_type)
#'     value <- rawToChar(value)
#'     Encoding(value) <- charset
#'     read.dcf(value)
#'   }
#'   return(make_parsers(f, fixed = "text/x-dcf"))
#' }
#' add_parser("dcf", parser_dcf)
#' @export
add_parser <- function(alias, parser, verbose = TRUE) {

  if (!is.null(.globals$parsers[[alias]])) {
    if (isTRUE(verbose)) {
      warning("Overwriting parser: ", alias)
    }
  }

  stopifnot(is.function(parser))

  .globals$parsers[[alias]] <- parser

  invisible(list_parsers())
}

#' @export
#' @describeIn add_parser List currently registered parsers
list_parsers <- function() {
  .globals$parsers
}

#' @export
#' @describeIn add_parser Make named list. Mapping content-type with parser.
#' @param parser_function A single functions to map to one or more Content-Type.
#' @param fixed A character vector of fixed string to be matched against a request Content-Type.
#' @param regex A character vector of [regex] string to be matched against a request Content-Type.
#' @param shortname A character value to reference a parser by a shortname.
#' Content-Type.
make_parsers <- function(parser_function, fixed = NULL, regex = NULL, shortname = NULL) {
  if (any(shortname %in% c("fixed", "regex"))) {
    stop("Shortnames `fixed` and `regex` are reserved for internal use.")
  }
  m <- function(n) {
    structure(
      replicate(
        length(n),
        parser_function),
      names = n
    )
  }
  parsers <- m(shortname)
  if (length(fixed) > 0) {
    parsers <- c(parsers, list("fixed" = m(fixed)))
  }
  if (length(regex) > 0) {
    parsers <- c(parsers, list("regex" = m(regex)))
  }
  invisible(parsers)
}

#' Plumber Parsers
#'
#' Parsers are used in Plumber to transform the raw body content received
#' by a request to the API. Extra parameters may be provided to parser
#' functions when adding the parser to plumber. This will allow for
#' non-default behavior.
#'
#' Parsers are optional. When unspecified, only the [parser_json()] and
#' [parser_query()] are available. You can use `@parser parser` tag to
#' activate parsers per endpoint. Multiple parsers can be activated for
#' the same endpoint using multiple `@parser parser` tags.
#'
#' User should be aware that `rds` parsing should only be done from a
#' trusted source. Do not accept `rds` files blindly.
#'
#' See [list_parsers()] for a list of registered parsers.
#'
#' @param ... parameters supplied to the appropriate internal function
#' @describeIn parsers Query string parser
#' @examples
#' \dontrun{
#' # Overwrite `text/json` parsing behavior to not allow JSON vectors to be simplified
#' #* @parser json simplifyVector = FALSE
#' # Activate `rds` parser in a multipart request
#' #* @parser multi
#' #* @parser rds
#' pr <- plumber$new()
#' pr$handle("GET", "/upload", function(rds) {rds}, parsers = c(parser_multi(), parser_rds()))
#' }
#' @export
parser_query <- function() {
  f <- parser_text(parseQS)$text
  return(make_parsers(f, fixed = "application/x-www-form-urlencoded", shortname = "query"))
}


#' @describeIn parsers JSON parser
#' @export
parser_json <- function(...) {
  f <- parser_text(function(value) {
    safeFromJSON(value, ...)
  })$text
  return(make_parsers(f, fixed = c("application/json", "text/json"), regex = "json$", shortname = "json"))
}


#' @describeIn parsers Helper parser to parse plain text
#' @param parse_fn function to further decode a text string into an object
#' @export
parser_text <- function(parse_fn = identity) {
  stopifnot(is.function(parse_fn))
  f <- function(value, content_type = NULL, ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    parse_fn(value)
  }
  return(make_parsers(f, fixed = "text/plain", regex = "^text/", shortname = "text"))
}


#' @describeIn parsers YAML parser
#' @export
parser_yaml <- function(...) {
  f <- parser_text(function(val) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("yaml must be installed for the yaml parser to work")
    }
    yaml::yaml.load(val, ..., eval.expr = FALSE)
  })$text
  return(make_parsers(f,  fixed = c("application/yaml", "application/x-yaml", "text/yaml", "text/x-yaml")))
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
  f <- parser_read_file(function(val) {
    utils::read.csv(val, ...)
  })
  return(make_parsers(f, fixed = c("application/csv", "application/x-csv", "text/csv", "text/x-csv")))
}


#' @describeIn parsers TSV parser
#' @export
parser_tsv <- function(...) {
  f <- parser_read_file(function(val) {
    utils::read.delim(val, ...)
  })
  return(make_parsers(f, fixed = c("application/tab-separated-values", "text/tab-separated-values")))
}


#' @describeIn parsers RDS parser
#' @export
parser_rds <- function(...) {
  f <- parser_read_file(function(value) {
    readRDS(value, ...)
  })
  return(make_parsers(f, fixed = "application/rds"))
}


#' @describeIn parsers Octet stream parser
#' @export
parser_octet <- function() {
  f <- function(value, filename = NULL, ...) {
    attr(value, "filename") <- filename
    value
  }
  return(make_parsers(f, fixed = "application/octet-stream", shortname = "octet"))
}


#' @describeIn parsers Multi part parser. This parser will then parse each individual body with its respective parser
#' @export
#' @importFrom webutils parse_multipart
parser_multi <- function() {
  f <- function(value, content_type, parsers, ...) {
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
  return(make_parsers(f, fixed = "multipart/form-data"))
}

#' @describeIn parsers All parsers
#' @export
parser_all <- function() {
  parsers <- .globals$parsers
  parsers$all <- NULL
  return(invisible(
    # Lambda function to get each parser `p()` list
    Reduce(function(l, p) {utils::modifyList(p(), l)}, parsers, init = list())
  ))
}

#' @describeIn parsers No parser
#' @export
parser_none <- function() {
  return(invisible(
    list()
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
  add_parser("all", parser_all)
  add_parser("none", parser_none)
}
