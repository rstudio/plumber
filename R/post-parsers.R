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
#' @param regex A pattern to match against the content-type of each part of
#' the request body.
#'
#' @details Pattern is stored in attribute `regex` of an added parser.
#' For instance, the \code{parser_json} pattern is `application/json`.
#' If `regex` is not provided and no attribute `regex` is set on `parser`,
#' parser attribute `regex` will be set to `application/{name}`.
#' Detection is done assuming content-type starts with pattern and is
#' case insensitive.
#'
#' Parser function structure is something like
#' ```r
#' parser <- function(...) {
#'   function(value, ...) {
#'     # do something with raw value
#'   }
#' }
#' ```
#'
#' It should return a named list when not used with content-type multipart
#' if you want values to map to plumber endpoint function args.
#'
#' @example
#' parser_json <- function(...) {
#'   function(value, content_type = "application/json", ...) {
#'     charset <- getCharacterSet(content_type)
#'     value <- rawToChar(value)
#'     Encoding(value) <- charset
#'     safeFromJSON(value)
#'   }
#' }
#' @md
#' @export
addParser <- function(name, parser, regex = attr(parser, "regex")) {
  if (is.null(.globals$parsers)) {
    .globals$serializers <- list()
  }
  if (!is.null(.globals$parser[[name]])) {
    stop("Already have a parser by the name of ", name)
  }
  if (is.null(regex)) {
    attr(parser, "regex") <- paste0("application/", name)
  } else {
    attr(parser, "regex") <- regex
  }
  .globals$parser[[name]] <- parser
}



#' JSON
#' @rdname parsers
#' @param ... Raw values and headers are passed there.
#' @export
parser_json <- function(...) {
  function(value, content_type = "application/json", ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    safeFromJSON(value)
  }
}
attr(parser_json, "regex") <- "application/json"




#' QUERY STRING
#' @rdname parsers
#' @param ... Raw values and headers are passed there.
#' @export
parser_query <- function(...) {
  function(value, content_type = "application/x-www-form-urlencoded", ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    parseQS(value)
  }
}
attr(parser_query, "regex") <- "application/x-www-form-urlencoded"




#' TEXT
#' @rdname parsers
#' @param ... Raw values and headers are passed there.
#' @export
parser_text <- function(...) {
  function(value, content_type = "text/html", ...) {
    charset <- getCharacterSet(content_type)
    value <- rawToChar(value)
    Encoding(value) <- charset
    value
  }
}
attr(parser_text, "regex") <- "text/"




#" RDS
#' @rdname parsers
#' @param ... Raw values and headers are passed there.
#' @export
parser_rds <- function(...) {
  function(value, filename, ...) {
    tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
    writeBin(value, tmp)
    on.exit(file.remove(tmp))
    list(readRDS(tmp))
  }
}
attr(parser_rds, "regex") <- "application/rds"




#' OCTET
#' @rdname parsers
#' @param ... Raw values and headers are passed there.
#' @export
parser_octet <- function(...) {
  function(value, filename, ...) {
    if (!missing(filename)) {
      if (interactive()) {
        writeBin(value, basename(filename))
        ret <- basename(filename)
        attr(ret, "filename") <- filename
      } else {
        tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
        writeBin(value, tmp)
        ret <- tmp
        attr(ret, "filename") <- filename
      }
      return(ret)
    } else {
      return(value)
    }
  }
}
attr(parser_octet, "regex") <- "application/octet"




#' @include globals.R
.globals$parsers[["json"]] <- parser_json
.globals$parsers[["query"]] <- parser_query
.globals$parsers[["text"]] <- parser_text
.globals$parsers[["rds"]] <- parser_rds
.globals$parsers[["octet"]] <- parser_octet
