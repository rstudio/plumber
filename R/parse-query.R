queryStringFilter <- function(req){
  handled <- req$.internal$queryStringHandled
  if (is.null(handled) || handled != TRUE) {
    qs <- req$QUERY_STRING
    args <- parseQS(qs)
    req$args <- c(req$args, args)
    req$argsQuery <- args
    req$.internal$queryStringHandled <- TRUE
  }
  forward()
}

#' @noRd
parseQS <- function(qs){

  if (is.null(qs) || length(qs) == 0L || qs == "") {
    return(list())
  }

  # Looked into using webutils::parse_query()
  # Currently not pursuing `webutils::parse_query` as it does not handle Encoding issues handled below
  # (Combining keys are also not handled by `webutils::parse_query`)

  qs <- stri_replace_first_regex(qs, "^[?]", "")
  qs <- chartr("+", " ", qs)

  args <- stri_split_fixed(qs, "&", omit_empty = TRUE)[[1L]]
  kv <- lapply(args, function(x) {
    # returns utf8 strings
    httpuv::decodeURIComponent(stri_split_fixed(x, "=", omit_empty = TRUE)[[1]])
  })
  kv <- kv[vapply(kv, length, numeric(1)) == 2] # Ignore incompletes

  if (length(kv) == 0) {
    # return a blank list of args if there is nothing to parse
    return(list())
  }

  keys <- vapply(kv, `[`, character(1), 1)
  kenc <- unique(Encoding(keys))
  if (any(kenc != "unknown")) {
    # https://github.com/rstudio/plumber/pull/314#discussion_r239992879
    non_ascii <- setdiff(kenc, "unknown")
    warning(
      "Query string parameter received in non-ASCII encoding. Received: ",
      paste0(non_ascii, collapse = ", ")
    )
  }

  vals <- lapply(kv, `[`, 2)
  names(vals) <- keys

  # If duplicates, combine
  combine_keys(vals, type = "query")
}

createPathRegex <- function(pathDef, funcParams = NULL){
  # Create a regex from the defined path, substituting variables where appropriate
  match <- stri_match_all(
    pathDef,
    # capture any plumber type (<arg:TYPE>).
    # plumberToApiType(types) will yell if it is unknown
    # and can not be guessed from endpoint function args)
    # <arg> will be given the TYPE `defaultApiType`
    regex = "/<(\\.?[a-zA-Z][\\w_\\.]*)(?::([^>]*))?>"
  )[[1]]
  names <- match[,2]
  # No path params
  if (length(names) <= 1 && is.na(names)) {
    return(
      list(
        names = character(),
        types = NULL,
        regex = paste0("^", pathDef, "$"),
        parsers = NULL,
        areArrays = NULL
      )
    )
  }

  plumberTypes <- stri_replace_all(match[,3], "$1", regex = "^\\[([^\\]]*)\\]$")
  if (length(funcParams) > 0) {
    # Override with detection of function args if type not found in map
    idx <- !(plumberTypes %in% names(apiTypesInfo))
    plumberTypes[idx] <- sapply(funcParams, `[[`, "type")[names[idx]]
  }
  apiTypes <- plumberToApiType(plumberTypes, inPath = TRUE)

  areArrays <- stri_detect_regex(match[,3], "^\\[[^\\]]*\\]$")
  if (length(funcParams) > 0) {
    # Override with detection of function args when false or na
    idx <- (is.na(areArrays) | !areArrays)
    areArrays[idx] <- sapply(funcParams, `[[`, "isArray")[names[idx]]
  }
  areArrays[is.na(areArrays)] <- defaultIsArray

  pathRegex <- pathDef
  regexps <- typesToRegexps(apiTypes, areArrays)
  for (regex in regexps) {
    pathRegex <- stri_replace_first_regex(
      pathRegex,
      pattern = "/(?:<\\.?[a-zA-Z][\\w_\\.:\\[\\]]*>)(/?)",
      replacement = paste0("/(", regex, ")$1")
    )
  }

  list(
    names = names,
    types = apiTypes,
    regex = paste0("^", pathRegex, "$"),
    parsers = typesToParsers(apiTypes, areArrays),
    areArrays = areArrays
  )
}


typesToRegexps <- function(apiTypes, areArrays = FALSE) {
  # return vector of regex strings
  mapply(
    function(x, y) {x[[y]]},
    apiTypesInfo[apiTypes],
    ifelse(areArrays, "openApiRegexArray", "openApiRegex"),
    USE.NAMES = FALSE
  )
}


typesToParsers <- function(apiTypes, areArrays = FALSE) {
  # return list of functions
  mapply(
    function(x, y) {x[[y]]},
    apiTypesInfo[apiTypes],
    ifelse(areArrays, "parserArray", "parser"),
    USE.NAMES = FALSE
  )
}


# Extract the params from a given path
# @param def is the output from createPathRegex
extractPathParams <- function(def, path){
  vals <- as.list(stri_match(path, regex = def$regex)[,-1])
  names(vals) <- def$names

  if (!is.null(def$parsers)){
    # Run each value through its parser
    for (i in 1:length(vals)){
      vals[[i]] <- def$parsers[[i]](vals[[i]])
    }
  }

  vals
}


#' combine args that share the same name
#' @noRd
#' @importFrom stats setNames
combine_keys <- function(obj, type) {

  keys <- names(obj)
  unique_keys <- unique(keys)

  # If a query string as the same amount of unique keys as keys,
  # then return it as it
  # (`"multi"` type objects MUST be processed, regardless if the unique key count is the same)
  if (
    length(unique_keys) == length(keys) &&
    identical(type, "query")
  ) {
    return(obj)
  }

  vals <- unname(obj)

  cleanup_item <- switch(
    type,
    "query" =
      function(x) {
        unname(unlist(x))
      },
    "multi" =
      function(x) {
        if (length(x) == 1) {
          part <- x[[1]]
          filename <- part$filename
          parsed <- part$parsed

          if (!is.null(filename)) {
            # list(
            #   "myfile.json" = list(
            #     a = 1, b = 2
            #   )
            # )
            return(
              setNames(
                list(parsed),
                filename
              )
            )
          }
          # list(
          #   a = 1, b = 2
          # )
          return(parsed)
        }

        # length is > 1

        has_a_filename <- FALSE
        filenames <- lapply(x, function(part) {
          filename <- part$filename
          if (is.null(filename)) return("")
          has_a_filename <<- TRUE
          filename
        })

        parsed_items <- lapply(unname(x), `[[`, "parsed")

        if (!has_a_filename) {
          # return as is
          return(parsed_items)
        }

        return(setNames(parsed_items, filenames))
      },
    stop("unknown type: ", type)
  )

  # equivalent code output, `split` is much faster with larger objects
  # Testing on personal machine had a breakpoint around 150 letters as query parameters
  ## n <- 150
  ## k <- sample(letters, n, replace = TRUE)
  ## v <- as.list(sample(1L, n, replace = TRUE))
  ## microbenchmark::microbenchmark(
  ##   split = {
  ##     lapply(split(v, k), function(x) unname(unlist(x)))
  ##   },
  ##   not_split = {
  ##     lapply(unique(k), function(x) {
  ##       unname(unlist(v[k == x]))
  ##     })
  ##   }
  ## )
  vals <-
    if (length(unique_keys) > 150) {
      lapply(split(vals, keys), function(items) {
        cleanup_item(items)
      })
    } else {
      # n < 150
      lapply(unique_keys, function(key) {
        cleanup_item(vals[keys == key])
      })
    }
  names(vals) <- unique_keys

  vals
}
