bodyFilter <- function(req){
  handled <- req$.internal$bodyHandled
  if (is.null(handled) || handled != TRUE) {

    rook_input <- req$rook.input

    # This will return raw bytes
    # store raw body into req$bodyRaw
    req$bodyRaw <- rook_input$read()

    delayedAssign(
      "postBody",
      {
        rook_input$rewind()
        paste0(rook_input$read_lines(), collapse = "\n")
      },
      assign.env = req
    )

    req$.internal$bodyHandled <- TRUE
  }
  forward()
}

req_body_parser <- function(req, parsers = NULL) {
  if (length(parsers) == 0) {
    return(NULL)
  }
  type <- req$HTTP_CONTENT_TYPE
  bodyRaw <- req$bodyRaw
  if (is.null(bodyRaw)) {
    return(NULL)
  }
  body <- parse_body(bodyRaw, type, parsers)
  # store parsed body into req$body
  body
}
req_body_args <- function(req) {

  body <- req$body
  if (length(body) == 0) {
    return(list())
  }

  # Copy name over so that it is clearer as to the goal of the code below
  # The value returned from this function is set to `ret$argsBody`
  args_body <- body

  if (inherits(args_body, "plumber_multipart")) {
    args_body <- combine_keys(args_body, type = "multi")

  } else if (!is.null(args_body)) {
    # if it's a vector, then we should maybe bundle it as a list
    # this will allow for req$args to have the single piece of information
    # but it will deter from trying to formal name match against MANY false positive values
    if (!is.list(args_body)) {
      args_body_names <- names(args_body)
      # if there are no names at all, wrap it in a unnamed list to pass it through
      if (is.null(args_body_names) || all(args_body_names == "")) {
        args_body <- list(args_body)
      }
    }
  }
  args_body
}

parse_body <- function(body, content_type = NULL, parsers = NULL) {
  if (!is.raw(body)) {body <- charToRaw(body)}
  toparse <- list(value = body, content_type = content_type, parsers = parsers)
  parse_raw(toparse)
}

parse_raw <- function(toparse) {
  if (length(toparse$value) == 0L) return(list())
  parser <- parser_picker(
    toparse$content_type,
    toparse$value[1],
    toparse$filename,
    toparse$parsers
  )
  if (is.null(parser)) {
    message("No suitable parser found to handle request body type ", toparse$content_type, ".")
    return(list())
  }
  do.call(parser, toparse)
}

looks_like_json <- local({
  square_brace <- as.raw(91L)
  curly_brace <- as.raw(123L)
  function(first_byte) {
    first_byte == square_brace || first_byte == curly_brace
  }
})
parser_picker <- function(content_type, first_byte, filename = NULL, parsers = NULL) {

  content_type <- cleanup_content_type(content_type)

  # parse as json or a form
  if (length(content_type) == 0) {
    # fast default to json when first byte is 7b (ascii {) or 5b (ascii [)
    if (looks_like_json(first_byte)) {
      return(parsers$alias$json)
    }

    return(parsers$alias$form)
  }

  parser <- parsers$fixed[[content_type]]

  # return known parser (exact match)
  if (!is.null(parser)) {
    return(parser)
  }

  fpm <- stri_detect_regex(
    content_type,
    names(parsers$regex),
    max_count = 1
  )

  # return known parser (first regex pattern match)
  if (any(fpm)) {
    return(parsers$regex[[which(fpm)[1]]])
  }

  # parse as a form submission
  if (is.null(filename)) {
    return(parsers$alias$form)
  }

  # octet
  parsers$alias$octet
}


#' Manage parsers
#'
#' A parser is responsible for decoding the raw body content of a request into
#' a list of arguments that can be mapped to endpoint function arguments.
#' For instance, [parser_json()] parse content-type `application/json`.
#'
#' @param alias An alias to map parser from the `@parser` plumber tag to the global parsers list.
#' @param parser The parser function to be added. This build the parser function. See Details for more information.
#' @param fixed A character vector of fixed string to be matched against a request `content-type` to use `parser`.
#' @param regex A character vector of [regex] string to be matched against a request `content-type` to use `parser`.
#' @param verbose Logical value which determines if a warning should be
#' displayed when alias in map are overwritten.
#'
#' @details
#' When `parser` is evaluated, it should return a parser function.
#' Parser matching is done first by `content-type` header matching with `fixed` then by using
#' regular expressions with `regex`. Note that plumber strips `; charset*` from `content-type` header before matching.
#'
#' Plumber will try to use [parser_json()] (if available) when no `content-type` header is found and
#' the request body starts with `{` or `[`.
#'
#' Functions signature should include `value`, `...` and
#' possibly `content_type`, `filename`. Other parameters may be provided
#' if you want to use the headers from [webutils::parse_multipart()].
#'
#' Parser function structure is something like below.
#' ```r
#' function(parser_arguments_here) {
#'   # return a function to parse a raw value
#'   function(value, ...) {
#'     # do something with raw value
#'   }
#' }
#' ```
#'
#' @examples
#' # `content-type` header is mostly used to look up charset and adjust encoding
#' parser_dcf <- function(...) {
#'   function(value, content_type = "text/x-dcf", ...) {
#'     charset <- get_character_set(content_type)
#'     value <- rawToChar(value)
#'     Encoding(value) <- charset
#'     read.dcf(value, ...)
#'   }
#' }
#'
#' # Could also leverage existing parsers
#' parser_dcf <- function(...) {
#'   parser_read_file(function(tmpfile) {
#'     read.dcf(tmpfile, ...)
#'   })
#' }
#'
#' # Register the newly created parser
#' \dontrun{register_parser("dcf", parser_dcf, fixed = "text/x-dcf")}
#' @export
register_parser <- function(
  alias,
  parser,
  fixed = NULL,
  regex = NULL,
  verbose = TRUE
) {

  if (!is.null(.globals$parsers[[alias]])) {
    if (isTRUE(verbose)) {
      warning("Overwriting parser: ", alias)
    }
  }

  stopifnot(is.function(parser))

  if (length(c(fixed, regex)) == 0) {
    stop("At least one value of `fixed` and `regex` is required to register a parser")
  }

  # Init the parser function with outside arguments
  init_parser_func <- function(...) {
    parser_function <- do.call(parser, list(...))

    parser_formals <- formals(parser_function)
    if (!("..." %in% names(parser_formals))) {
      stop("For parser '", alias, "', please add a `...` argument to the returned function for possible future parameter expansion")
    }

    create_list <- function(names) {
      setNames(
        replicate(
          length(names),
          parser_function),
        names
      )
    }

    parser_info <- list(
      alias = create_list(alias)
    )
    if (length(fixed) > 0) {
      parser_info$fixed <- create_list(fixed)
    }
    if (length(regex) > 0) {
      parser_info$regex <- create_list(regex)
    }

    return(parser_info)
  }

  .globals$parsers[[alias]] <- init_parser_func
  invisible(.globals$parsers)
}

#' @describeIn register_parser Return all registered parsers
#' @export
registered_parsers <- function() {
  sort(names(.globals$parsers))
}

# ' @describeIn register_parser Select from global parsers and create a combined parser list for programmatic use.
# ' @param aliases Can be one of:
# '   * A character vector of `alias` names.
# '   * A named `list()` whose keys are `alias` names and values are arguments to be applied with [do.call()]
# '   * A `TRUE` value, which will default to combining all parsers. This is great for seeing what is possible, but not great for security purposes.
# '   * Already combined parsers. (Will be returned immediately.)
# '
# ' If `"all"` is found in any `alias` character value or list name, all remaining parsers will be added.  When using a list, aliases already defined will maintain their existing argument values.  All other parser aliases will use their default arguments.
# ' @examples
# ' # provide a character string
# ' make_parser("json")
# '
# ' # provide a named list with no arguments
# ' make_parser(list(json = list()))
# '
# ' # provide a named list with arguments; include `rds`
# ' make_parser(list(json = list(simplifyVector = FALSE), rds = list()))
# '
# ' # default plumber parsers
# ' make_parser(c("json", "form", "text", "octet", "multi"))
make_parser <- function(aliases) {
  if (inherits(aliases, "plumber_parsed_parsers")) {
    return(aliases)
  }
  if (isTRUE(aliases)) {
    # use all parsers
    aliases <- "all"
  }
  if (is.character(aliases)) {
    if (any(is.na(aliases))) {
      stop("aliases can not be `NA` values")
    }
    if ("all" %in% aliases) {
      # use all available parsers expect `all` and `none`
      aliases <- setdiff(registered_parsers(), c("all", "none"))
    }
    # turn aliases into a named list with empty values
    aliases <- setNames(
      replicate(length(aliases), {list()}),
      aliases
    )
  }

  stopifnot(is.list(aliases))
  if (is.null(names(aliases))) {
    stop("aliases must be able to convert to a named list")
  }

  local({
    aliases_not_found <- !(names(aliases) %in% registered_parsers())
    if (any(aliases_not_found)) {
      missing_aliases <- names(aliases)[aliases_not_found]
      stop("Aliases not available: ", paste0(missing_aliases, collapse = ", "), ". See: registered_parsers()")
    }
  })

  # if "all" is found, remove "all" and add all remaining registered parsers (except 'none') to the `aliases` list
  if ("all" %in% names(aliases)) {
    all_parser_names <- setdiff(registered_parsers(), c("all", "none"))
    # remove to avoid infinite recursion
    aliases$all <- NULL
    names_to_add <- setdiff(all_parser_names, names(aliases))
    if (length(names_to_add)) {
      aliases[names_to_add] <- replicate(length(names_to_add), list())
    }
  }

  # convert parser functions into initialized information
  parser_infos <-
    lapply(
      names(aliases),
      function(alias) {
        # get init function
        init_parser_func <- .globals$parsers[[alias]]
        # call outer parser function to init the params for inner function
        do.call(init_parser_func, aliases[[alias]])
      }
    )

  # combine information into a single list
  combined_parser_info <-
    Reduce(
      function(cur_parser_info, parser_info) {
        utils::modifyList(cur_parser_info, parser_info)
      },
      parser_infos,
      init = list()
    )

  class(combined_parser_info) <- c("plumber_parsed_parsers", class(combined_parser_info))
  combined_parser_info
}

#' Plumber Parsers
#'
#' Parsers are used in Plumber to transform request body received
#' by the API. Extra parameters may be provided to parser
#' functions when enabling them on router. This will allow for
#' non-default behavior.
#'
#' Parsers are optional. When unspecified, only default endpoint parsers are enabled.
#' You can use `@parser NAME` tag to enable parser on endpoint.
#' Multiple parsers can be enabled on the same endpoint using multiple `@parser NAME` tags.
#'
#' User should be aware that `rds` parsing should only be done from a
#' trusted source. Do not accept `rds` files blindly.
#'
#' See [registered_parsers()] for a list of registered parsers names.
#'
#' @param ... parameters supplied to the appropriate internal function
#' @describeIn parsers Form query string parser
#' @examples
#' \dontrun{
#' # Overwrite `text/json` parsing behavior to not allow JSON vectors to be simplified
#' #* @parser json list(simplifyVector = FALSE)
#' # Activate `rds` parser in a multipart request
#' #* @parser multi
#' #* @parser rds
#' pr <- Plumber$new()
#' pr$handle("GET", "/upload", function(rds) {rds}, parsers = c("multi", "rds"))
#' }
#' @export
parser_form <- function() {
  parser_text(parseQS)
}


#' @describeIn parsers JSON parser. See [jsonlite::parse_json()] for more details. (Defaults to using `simplifyVectors = TRUE`)
#' @export
parser_json <- function(...) {
  parser_text(function(txt_value) {
    safeFromJSON(txt_value, ...)
  })
}

#' @describeIn parsers GeoJSON parser. See [geojsonsf::geojson_sf()] for more details.
#' @export
parser_geojson <- function(...) {
  if (!requireNamespace("geojsonsf", quietly = TRUE)) {
    stop("`geojsonsf` must be installed for `parser_geojson` to work")
  }
  parser_text(function(val) {
    geojsonsf::geojson_sf(val, ...)
  })
}

#' @describeIn parsers Helper parser to parse plain text
#' @param parse_fn function to further decode a text string into an object
#' @export
parser_text <- function(parse_fn = identity) {
  stopifnot(is.function(parse_fn))
  function(value, content_type = NULL, ...) {
    charset <- get_character_set(content_type)
    txt_value <- rawToChar(value)
    Encoding(txt_value) <- charset
    parse_fn(txt_value)
  }
}


#' @describeIn parsers YAML parser. See [yaml::yaml.load()] for more details.
#' @export
parser_yaml <- function(...) {
  parser_text(function(val) {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("yaml must be installed for the yaml parser to work")
    }
    yaml::yaml.load(val, ..., eval.expr = FALSE)
  })
}

#' @describeIn parsers CSV parser. See [readr::read_csv()] for more details.
#' @export
parser_csv <- function(...) {
  parse_fn <- function(raw_val) {
    if (!requireNamespace("readr", quietly = TRUE)) {
      stop("`readr` must be installed for `parser_csv` to work")
    }
    readr::read_csv(raw_val, ...)
  }
  function(value, ...) {
    parse_fn(value)
  }
}


#' @describeIn parsers TSV parser. See [readr::read_tsv()] for more details.
#' @export
parser_tsv <- function(...) {
  parse_fn <- function(raw_val) {
    if (!requireNamespace("readr", quietly = TRUE)) {
      stop("`readr` must be installed for `parser_tsv` to work")
    }
    readr::read_tsv(raw_val, ...)
  }
  function(value, ...) {
    parse_fn(value)
  }
}


#' @describeIn parsers Helper parser that writes the binary body to a file and reads it back again using `read_fn`.
#'   This parser should be used when reading from a file is required.
#' @param read_fn function used to read a the content of a file. Ex: [readRDS()]
#' @export
parser_read_file <- function(read_fn = readLines) {
  stopifnot(is.function(read_fn))
  function(value, filename = "", ...) {
    tmp <- tempfile("plumb", fileext = paste0("_", basename(filename)))
    on.exit({
      if (file.exists(tmp)) {
        file.remove(tmp)
      }
    }, add = TRUE)
    writeBin(value, tmp)
    read_fn(tmp)
  }
}


#' @describeIn parsers RDS parser. See [readRDS()] for more details.
#' @export
parser_rds <- function(...) {
  parser_read_file(function(tmpfile) {
    # `readRDS()` does not work with `rawConnection()`
    readRDS(tmpfile, ...)
  })
}

#' @describeIn parsers feather parser. See [arrow::read_feather()] for more details.
#' @export
parser_feather <- function(...) {
  parser_read_file(function(tmpfile) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("`arrow` must be installed for `parser_feather` to work")
    }
    arrow::read_feather(tmpfile, ...)
  })
}

#' @describeIn parsers Arrow IPC parser. See [arrow::read_ipc_stream()] for more details.
#' @export
parser_arrow_ipc <- function(...) {
  parser_read_file(function(tmpfile) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("`arrow` must be installed for `parser_arrow_ipc` to work")
    }
    arrow::read_ipc_stream(tmpfile, ...)
  })
}

#' @describeIn parsers parquet parser. See [arrow::read_parquet()] for more details.
#' @export
parser_parquet <- function(...) {
  parser_read_file(function(tmpfile) {
    if (!requireNamespace("arrow", quietly = TRUE)) {
      stop("`arrow` must be installed for `parser_parquet` to work")
    }
    arrow::read_parquet(tmpfile, ...)
  })
}

#' @describeIn parsers Octet stream parser. Returns the raw content.
#' @export
parser_octet <- function() {
  function(value, ...) {
    return(value)
  }
}


#' @describeIn parsers Multi part parser. This parser will then parse each individual body with its respective parser.  When this parser is used, `req$body` will contain the updated output from [webutils::parse_multipart()] by adding the `parsed` output to each part.  Each part may contain detailed information, such as `name` (required), `content_type`, `content_disposition`, `filename`, (raw, original) `value`, and `parsed` (parsed `value`).  When performing Plumber route argument matching, each multipart part will match its `name` to the `parsed` content.
#' @export
#' @importFrom webutils parse_multipart
parser_multi <- function() {
  function(value, content_type, parsers, ...) {
    if (!stri_detect_fixed(content_type, "boundary=", case_insensitive = TRUE))
      stop("No boundary found in multipart content-type header: ", content_type)
    # Also remove surrounding quotes if they exist
    boundary <- stri_match_first_regex(content_type, "boundary=\"?([^; \"]{2,})\"?", case_insensitive = TRUE)[,2]
    toparse <- parse_multipart(value, boundary)

    # set the names of the items as the `name` of each item
    toparse_names <- vapply(toparse, function(x) {
      name <- x$name
      # null or character(0)
      if (length(name) == 0) {
        return("")
      }
      name
    }, character(1))
    names(toparse) <- toparse_names

    # content-type detection
    ret <- lapply(toparse, function(x) {
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
      # copy over to allow to return the updated `x` without `parsers`
      item <- x
      # add `parsers` to allow `parse_raw` to work
      item$parsers <- parsers
      # store the parsed information into `x`
      x$parsed <- parse_raw(item)
      # return the updated `webutils::parse_multipart()` output
      x
    })

    # set a class so `req$argsBody` can be reduced to a named list of values
    class(ret) <- "plumber_multipart"
    ret
  }
}

#' @describeIn parsers No parser. Will not process the postBody.
#' @export
parser_none <- function() {
  function(value, ...) {
    value
  }
}

register_parsers_onLoad <- function() {
  # parser alias names for plumbing
  register_parser("csv",       parser_csv,     fixed = c("application/csv", "application/x-csv", "text/csv", "text/x-csv"))
  register_parser("json",      parser_json,    fixed = c("application/json", "text/json"))
  register_parser("multi",     parser_multi,   fixed = "multipart/form-data", regex = "^multipart/")
  register_parser("octet",     parser_octet,   fixed = "application/octet-stream")
  register_parser("form",      parser_form,    fixed = "application/x-www-form-urlencoded")
  register_parser("rds",       parser_rds,     fixed = "application/rds")
  register_parser("feather",   parser_feather, fixed = c("application/vnd.apache.arrow.file", "application/feather"))
  register_parser("arrow_ipc", parser_arrow_ipc, fixed = c("application/vnd.apache.arrow.stream"))
  register_parser("parquet",   parser_parquet, fixed = "application/vnd.apache.parquet")
  register_parser("text",      parser_text,    fixed = "text/plain", regex = "^text/")
  register_parser("tsv",       parser_tsv,     fixed = c("application/tab-separated-values", "text/tab-separated-values"))
  # yaml types: https://stackoverflow.com/a/38000954/591574
  register_parser("yaml",      parser_yaml,    fixed = c("text/vnd.yaml", "application/yaml", "application/x-yaml", "text/yaml", "text/x-yaml"))
  register_parser("none",      parser_none,    regex = "*")
  register_parser("geojson",   parser_geojson, fixed = c("application/geo+json", "application/vdn.geo+json"))

  parser_all <- function() {
    stop("This function should never be called. It should be handled by `make_parser('all')`")
  }
  register_parser("all", parser_all, regex = "*")
}
