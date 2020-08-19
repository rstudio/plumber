queryStringFilter <- function(req){
  handled <- req$.internal$queryStringHandled
  if (is.null(handled) || handled != TRUE) {
    qs <- req$QUERY_STRING
    args <- parseQS(qs)
    req$argsQuery <- args
    req$args <- c(req$args, args)
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
        converters = NULL,
        areArrays = NULL
      )
    )
  }

  plumberTypes <- stri_replace_all(match[,3], "$1", regex = "^\\[([^\\]]*)\\]$")
  if (length(funcParams) > 0) {
    # Override with detection of function args if type not found in map
    idx <- !(plumberTypes %in% names(plumberToApiTypeMap))
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
    converters = typesToConverters(apiTypes, areArrays),
    areArrays = areArrays
  )
}


typesToRegexps <- function(apiTypes, areArrays = FALSE) {
  # return vector of regex strings
  mapply(
    function(x, y) {x[[y]]},
    apiTypesInfo[apiTypes],
    ifelse(areArrays, "regexArray", "regex"),
    USE.NAMES = FALSE
  )
}


typesToConverters <- function(apiTypes, areArrays = FALSE) {
  # return list of functions
  mapply(
    function(x, y) {x[[y]]},
    apiTypesInfo[apiTypes],
    ifelse(areArrays, "converterArray", "converter"),
    USE.NAMES = FALSE
  )
}


# Extract the params from a given path
# @param def is the output from createPathRegex
extractPathParams <- function(def, path){
  vals <- as.list(stri_match(path, regex = def$regex)[,-1])
  names(vals) <- def$names

  if (!is.null(def$converters)){
    # Run each value through its converter
    for (i in 1:length(vals)){
      vals[[i]] <- def$converters[[i]](vals[[i]])
    }
  }

  vals
}


#' combine args that share the same name
#' @noRd
combine_keys <- function(obj, type) {

  keys <- names(obj)
  unique_keys <- unique(keys)

  if (length(unique_keys) == length(keys) || is.null(keys)) {
    return(obj)
  }

  vals <- unname(obj)

  extra_args <- NULL
  if (type == "multi") {
    # handle unnamed args by removing them from being merged and adding them back again at the end
    no_name_positions <- (keys == "")
    if (any(no_name_positions)) {
      extra_args <- vals[no_name_positions]
      vals <- vals[!no_name_positions]
      keys <- keys[!no_name_positions]
      unique_keys <- setdiff(unique_keys, "")
    }
  }

  cleanup_item <- switch(
    type,
    "query" =
      function(x) {
        unname(unlist(x))
      },
    "multi" =
      function(x) {
        if (length(x) == 1) {
          # return first item only
          return(x[[1]])
        }

        # return list of internal named items
        # aka... unlist the top layer only. Maintain the inner layer names
        x_new <- lapply(unname(x), function(x_item) {
          if (is.atomic(x_item)) {
            # handles things like `parse_text` which returns atomic values
            return(list(x_item))
          }

          # handles things like `parse_octet` which returns a (possibly) named list
          x_item
        })
        as.list(unlist(x_new, recursive = FALSE))
      }
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

  # append any remaining unnamed arguments (for `type = multi` only)
  c(vals, extra_args)
}
