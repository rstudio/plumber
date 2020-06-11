queryStringFilter <- function(req){
  handled <- req$.internal$queryStringHandled
  if (is.null(handled) || handled != TRUE) {
    qs <- req$QUERY_STRING
    args <- parseQS(qs)
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

  qs <- stri_replace_first_regex(qs, "^[?]", "")
  #qs <- stri_replace_all_fixed(qs, "+", " ")

  args <- stri_split_fixed(qs, "&", omit_empty = TRUE)[[1L]]
  kv <- lapply(args, function(x) {
    # returns utf8 strings
    httpuv::decodeURIComponent(stri_split_fixed(x, "=", omit_empty = TRUE)[[1]])
  })
  kv <- kv[lengths(kv) == 2] # Ignore incompletes

  if (length(kv) == 0) {
    # return a blank list of args if there is nothing to parse
    return(list())
  }

  k <- vapply(kv, "[", character(1), 1)
  kenc <- unique(Encoding(k))
  if (any(kenc != "unknown")) {
    # https://github.com/rstudio/plumber/pull/314#discussion_r239992879
    non_ascii <- setdiff(kenc, "unknown")
    warning(
      "Query string parameter received in non-ASCII encoding. Received: ",
      paste0(non_ascii, collapse = ", ")
    )
  }

  v <- lapply(kv, "[", 2)
  # If duplicates, combine
  v <- sapply(unique(k), function(x) do.call(c, v[x == k]), simplify = FALSE)

  return(v)
}

createPathRegex <- function(pathDef, funcParams = NULL){
  # Create a regex from the defined path, substituting variables where appropriate
  match <- stri_match_all(
    pathDef,
    # capture any plumber type (<arg:TYPE>).
    # plumberToSwaggerType(types) will yell if it is unknown
    # and can not be guessed from endpoint function args)
    # <arg> will be given the TYPE `defaultSwaggerType`
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

  types <- stri_replace_all(match[,3], "$1", regex = "^\\[([^\\]]*)\\]$")
  if (length(funcParams) > 0) {
    # Override with detection of function args if type not found in map
    idx <- !(types %in% names(plumberToSwaggerTypeMap))
    types[idx] <- sapply(funcParams, `[[`, "type")[names[idx]]
  }
  types <- plumberToSwaggerType(types, inPath = TRUE)

  areArrays <- stri_detect_regex(match[,3], "^\\[[^\\]]*\\]$")
  if (length(funcParams) > 0) {
    # Override with detection of function args when false or na
    idx <- (is.na(areArrays) | !areArrays)
    areArrays[idx] <- sapply(funcParams, `[[`, "isArray")[names[idx]]
  }
  areArrays <- areArrays & supportsArray(types)
  areArrays[is.na(areArrays)] <- defaultSwaggerIsArray

  pathRegex <- pathDef
  regexps <- typesToRegexps(types, areArrays)
  for (regex in regexps) {
    pathRegex <- stri_replace_first_regex(
      pathRegex,
      pattern = "/(?:<\\.?[a-zA-Z][\\w_\\.:\\[\\]]*>)(/?)",
      replacement = paste0("/(", regex, ")$1")
    )
  }

  list(
    names = names,
    types = types,
    regex = paste0("^", pathRegex, "$"),
    converters = typeToConverters(types, areArrays),
    areArrays = areArrays
  )
}


typesToRegexps <- function(swaggerTypes, areArrays = FALSE) {
  # return vector of regex strings
  mapply(
    function(x, y) {x[[y]]},
    swaggerTypeInfo[swaggerTypes],
    ifelse(areArrays, "regexArray", "regex"),
    USE.NAMES = FALSE
  )
}


typeToConverters <- function(swaggerTypes, areArrays = FALSE) {
  # return list of functions
  mapply(
    function(x, y) {x[[y]]},
    swaggerTypeInfo[swaggerTypes],
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
