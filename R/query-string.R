queryStringFilter <- function(req){
  handled <- req$.internal$queryStringHandled
  if (is.null(handled) || handled != TRUE){
    qs <- req$QUERY_STRING
    args <- parseQS(qs)
    req$args <- c(req$args, args)
    req$.internal$queryStringHandled <- TRUE
  }
  forward()
}

#' @noRd
parseQS <- function(qs){
  if (is.null(qs) || length(qs) == 0 || qs == "") {
    return(list())
  }
  if (stri_startswith_fixed(qs, "?")) {
    qs <- substr(qs, 2, nchar(qs))
  }

  parts <- strsplit(qs, "&", fixed = TRUE)[[1]]
  kv <- strsplit(parts, "=", fixed = TRUE)
  kv <- kv[vapply(kv, length, numeric(1)) == 2] # Ignore incompletes

  if (length(kv) == 0) {
    # return a blank list of args if there is nothing to parse
    return(list())
  }

  keys <- httpuv::decodeURIComponent(vapply(kv, "[[", character(1), 1)) # returns utf8 strings
  if (any(Encoding(keys) != "unknown")) {
    # https://github.com/rstudio/plumber/pull/314#discussion_r239992879
    non_ascii <- setdiff(unique(Encoding(keys)), "unknown")
    warning(
      "Query string parameter received in non-ASCII encoding. Received: ",
      paste0(non_ascii, collapse = ", ")
    )
  }

  vals <- vapply(kv, "[[", character(1), 2)
  vals <- httpuv::decodeURIComponent(vals) # returns utf8 strings

  ret <- as.list(vals)
  names(ret) <- keys

  # If duplicates, combine
  combine_elements <- function(name){
    unname(unlist(ret[names(ret)==name]))
  }

  unique_names <- unique(names(ret))

  ret <- lapply(unique_names, combine_elements)
  names(ret) <- unique_names

  ret
}

createPathRegex <- function(pathDef){
  # Create a regex from the defined path, substituting variables where appropriate
  match <- stringi::stri_match_all(
    pathDef,
    # capture any plumber type (<arg:TYPE>) (typesToRegexps(type) will yell if it is unknown)
    # <arg> will be given the TYPE `defaultSwaggerType`
    regex = "/<(\\.?[a-zA-Z][\\w_\\.]*)(:([^>]*|\\[[^>]*\\](?:\\*)?))?>"
  )[[1]]
  names <- match[,2]
  types <- stringi::stri_replace_all(match[,4], "$1$2", regex = "^\\[([^\\]]*)\\]\\*?$|^([^\\*])\\*?$")
  serializations <- stringi::stri_detect_regex(match[,4], "^\\[[^\\]]*\\]\\*?$")
  if (length(names) <= 1 && is.na(names)) {
    return(
      list(
        names = character(),
        types = NULL,
        regex = paste0("^", pathDef, "$"),
        converters = NULL,
        serializations = NULL
      )
    )
  }
  if (length(types) > 0) {
    types[is.na(types)] <- defaultSwaggerType
  }

  if (length(serializations) > 0) {
    serializations[is.na(serializations)] <- defaultSwaggerSerialization
  }

  pathRegex <- pathDef
  regexps <- typesToRegexps(types, serializations)
  for (regex in regexps) {
    pathRegex <- stringi::stri_replace_first_regex(
      pathRegex,
      pattern = "/(<\\.?[a-zA-Z][\\w_\\.:\\[\\]\\*]*>)(/?)",
      replacement = paste0("/(", regex, ")$2")
    )
  }

  list(
    names = names,
    types = types,
    regex = paste0("^", pathRegex, "$"),
    converters = typeToConverters(types, serializations),
    serializations = serializations
  )
}


typesToRegexps <- function(types, serializations) {
  # return vector of regex strings
  mapply(
    function(x, y) {x[[y]]},
    swaggerTypeInfo[plumberToSwaggerType(types)],
    ifelse(serializations, "regexSerialization", "regex")
  )
}


typeToConverters <- function(types, serializations) {
  # return list of functions
  mapply(
    function(x, y) {x[[y]]},
    swaggerTypeInfo[plumberToSwaggerType(types)],
    ifelse(serializations, "converterSerialization", "converter")
  )
}


# Extract the params from a given path
# @param def is the output from createPathRegex
extractPathParams <- function(def, path){
  vals <- as.list(stringi::stri_match(path, regex = def$regex)[,-1])
  names(vals) <- def$names

  if (!is.null(def$converters)){
    # Run each value through its converter
    for (i in 1:length(vals)){
      vals[[i]] <- def$converters[[i]](vals[[i]])
    }
  }

  vals
}
