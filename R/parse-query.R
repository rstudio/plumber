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

  # If duplicates, combine
  unique_keys <- unique(keys)

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
      lapply(split(vals, keys), function(items) unname(unlist(items)))
    } else {
      # n < 150
      lapply(unique_keys, function(key) {
        unname(unlist(vals[keys == key]))
      })
    }
  names(vals) <- unique_keys

  return(vals)
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
  areArrays <- areArrays & apiTypes %in% filterApiTypes(TRUE, "arraySupport")
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
