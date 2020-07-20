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


#' Manage parsers
#'
#' A parser is responsible for decoding the raw body content of a request into
#' a list of arguments that can be mapped to endpoint function arguments.
#' For instance, [parser_json()] parse content-type `application/json`.
#'
#' @param alias An alias to map parser from the `@parser` plumber tag to the global parsers list.
#' @param parser The parser function to be added. This build the parser function.
#' @param fixed A character vector of fixed string to be matched against a request `content-type` to use `parser`.
#' @param regex A character vector of [regex] string to be matched against a request `content-type` to use `parser`.
#' @param shortname A character value to reference a parser by a shortname. (For internal use only)
#' @param verbose Logical value which determines if a warning should be
#' displayed when alias in map are overwritten.
#'
#' @details
#' When `parser` is evaluated, it should return a parser function.
#' Parser matching is done first by `content-type` header matching on `fixed` then by using a
#' regular expressions on `regex`. Note that plumber strip the header from `; charset*` to
#' perform matching.
#'
#' There is a special case when no `content-type` header is
#' provided that will use a [parser_json()] when it detects a `json` string.
#'
#' Functions signature should include `value`, `...` and
#' possibly `content_type`, `filename`. Other parameters may be provided
#' if you want to use the headers from [webutils::parse_multipart()].
#'
#' Parser function structure is something like below.
#' ```r
#' parser <- () {
#'  function(value, ...) {
#'   # do something with raw value
#'  }
#' }
#' ```
#'
#' @examples
#' # `content-type` header is mostly used to look up charset and adjust encoding
#' parser_dcf <- function() {
#'   function(value, content_type = "text/x-dcf", ...) {
#'     charset <- getCharacterSet(content_type)
#'     value <- rawToChar(value)
#'     Encoding(value) <- charset
#'     read.dcf(value)
#'   }
#' }
#' add_parser("dcf", parser_dcf, fixed = "text/x-dcf")
#' @export
add_parser <- function(alias, parser, fixed = NULL, regex = NULL, shortname = NULL, verbose = TRUE) {

  if (!is.null(.globals$parsers[[alias]])) {
    if (isTRUE(verbose)) {
      warning("Overwriting parser: ", alias)
    }
  }

  stopifnot(is.function(parser))

  if (length(c(fixed, regex, shortname))) {

    parsers_list <- function(...) {

      parser_function <- do.call(parser, list(...))

      create_list <- function(names) {
        stats::setNames(
          replicate(
            length(names),
            parser_function),
          names
        )
      }

        parsers <- list()

        if (length(shortname) > 0) {
          parsers[[shortname]] <- parser_function
        }
        if (length(fixed) > 0) {
          parsers$fixed <- create_list(fixed)
        }
        if (length(regex) > 0) {
          parsers$regex <- create_list(regex)
        }

        return(parsers)

    }

  } else {

    parsers_list = parser

  }

  .globals$parsers[[alias]] <- parsers_list

  invisible(list_parsers())
}

#' @export
#' @describeIn add_parser List currently registered parsers
list_parsers <- function() {
  .globals$parsers
}

#' @describeIn add_parser Select from global parsers and create
#' a formatted parsers list for programmatic use.
#' @export
select_parsers <- function(alias = character()) {
  parsers <- .globals$parsers[alias]
  # remove to avoid infinite recursion
  parsers$all <- NULL
  return(invisible(
    # Lambda function to get each parser `p()` list
    Reduce(function(l, p) {utils::modifyList(l, p())}, parsers, init = list())
  ))
}

#' Plumber Parsers
#'
#' Parsers are used in Plumber to transform the raw body content received
#' by a request to the API. Extra parameters may be provided to parser
#' functions when adding the parser to plumber. This will allow for
#' non-default behavior.
#'
#' Parsers are optional. When unspecified, only the [parser_json()],
#' [parser_octet()], [parser_query()] and [parser_text()] are available.
#' You can use `@parser parser` tag to activate parsers per endpoint.
#' Multiple parsers can be activated for the same endpoint using multiple `@parser parser` tags.
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


#' @describeIn parsers YAML parser
#' @export
parser_yaml <- function(...) {
  parser_text(function(val) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("yaml must be installed for the yaml parser to work")
    }
    yaml::yaml.load(val, ..., eval.expr = FALSE)
  })
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
  parser_read_file(function(val) {
    utils::read.csv(val, ...)
  })
}


#' @describeIn parsers TSV parser
#' @export
parser_tsv <- function(...) {
  parser_read_file(function(val) {
    utils::read.delim(val, ...)
  })
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
  function(value, content_type, parsers, ...) {
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
}

#' @describeIn parsers All parsers (For internal use only)
#' @export
parser_all <- function() {
  select_parsers(names(.globals$parsers))
}

#' @describeIn parsers No parser (For internal use only)
#' @export
parser_none <- function() {
  select_parsers()
}

add_parsers_onLoad <- function() {

  # parser alias names for plumbing
  add_parser("csv", parser_csv, fixed = c("application/csv", "application/x-csv", "text/csv", "text/x-csv"))
  add_parser("json", parser_json, fixed = c("application/json", "text/json"), regex = "json$", shortname = "json")
  add_parser("multi", parser_multi, fixed = "multipart/form-data")
  add_parser("octet", parser_octet, fixed = "application/octet-stream", shortname = "octet")
  add_parser("query", parser_query, fixed = "application/x-www-form-urlencoded", shortname = "query")
  add_parser("rds", parser_rds, fixed = "application/rds")
  add_parser("text", parser_text, fixed = "text/plain", regex = "^text/", shortname = "text")
  add_parser("tsv", parser_tsv, fixed = c("application/tab-separated-values", "text/tab-separated-values"))
  add_parser("yaml", parser_yaml, fixed = c("application/yaml", "application/x-yaml", "text/yaml", "text/x-yaml"))
  add_parser("all", parser_all)
  add_parser("none", parser_none)
}
