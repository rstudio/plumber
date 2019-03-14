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

#' @importFrom utils URLdecode
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
  kv <- kv[sapply(kv, length) == 2] # Ignore incompletes

  keys <- sapply(kv, "[[", 1)
  keys <- unname(sapply(keys, URLdecode))

  vals <- sapply(kv, "[[", 2)
  vals[is.na(vals)] <- ""
  vals <- unname(sapply(vals, URLdecode))

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
    # capture any plumber type (<arg:TYPE>) (typeToRegex(type) will yell if it is unknown)
    # <arg> will be given the TYPE `defaultSwaggerType`
    regex = "/<(\\.?[a-zA-Z][\\w_\\.]*)(:([^>]*))?>"
  )[[1]]
  names <- match[,2]
  types <- match[,4]
  if (length(names) <= 1 && is.na(names)){
    return(
      list(
        names = character(),
        types = NULL,
        regex = paste0("^", pathDef, "$"),
        converters = NULL
      )
    )
  }
  if (length(types) > 0) {
    types[is.na(types)] <- defaultSwaggerType
  }

  typedRegexs <- typeToRegex(types)
  pathRegex <- pathDef
  for (typedRegex in typedRegexs) {
    regexReplacement <- paste0("/(", typedRegex, ")$2")
    pathRegex <- stringi::stri_replace_first_regex(
      pathRegex,
      pattern = "/(<\\.?[a-zA-Z][\\w_\\.:]*>)(/?)",
      replacement = regexReplacement
    )
  }

  list(
    names = names,
    types = types,
    regex = paste0("^", pathRegex, "$"),
    converters = typeToConverters(types)
  )
}


typeToRegex <- function(type){
  # return vector of regex strings
  vapply(
    swaggerTypeInfo[plumberToSwaggerType(type)],
    `[[`, character(1), "regex"
  )
}


typeToConverters <- function(type) {
  # return list of functions
  lapply(
    swaggerTypeInfo[plumberToSwaggerType(type)],
    `[[`, "converter"
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
