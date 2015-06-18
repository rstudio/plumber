queryStringFilter <- function(req){
  qs <- req$QUERY_STRING
  args <- parseQS(qs)
  req$args <- c(req$args, args)
  forward()
}

parseQS <- function(qs){
  if (is.null(qs) || length(qs) == 0 || qs == ""){
    return(list())
  }
  if (stri_startswith_fixed(qs, "?")){
    qs <- substr(qs, 2, nchar(qs))
  }

  qs <- gsub("+", " ", qs, fixed=TRUE)

  parts <- strsplit(qs, "&", fixed=TRUE)[[1]]
  kv <- strsplit(parts, "=", fixed=TRUE)
  kv <- kv[sapply(kv, length) == 2] # Ignore incompletes

  keys <- sapply(kv, "[[", 1)
  keys <- unname(sapply(keys, URLdecode))

  vals <- sapply(kv, "[[", 2)
  vals[is.na(vals)] <- ""
  vals <- unname(sapply(vals, URLdecode))

  ret <- as.list(vals)
  names(ret) <- keys

  ret
}

createPathRegex <- function(pathDef){
  # Create a regex from the defined path, substituting variables where appropriate
  names <- stringi::stri_match_all(pathDef, regex="/:(\\.?[a-zA-Z][\\w_\\.]*)/?")[[1]][,2]
  re <- stringi::stri_replace_all(pathDef, "/([^\\\\./]+)$2", regex="/(:\\.?[a-zA-Z][\\w_\\.]*)(/?)")
  list(names = names, regex = re)
}

# Extract the params from a given path
# @param def is the output from createPathRegex
extractParams <- function(def, path){
  vals <- stringi::stri_match(path, regex = def$regex)[,-1]
  names(vals) <- def$names
  vals
}
