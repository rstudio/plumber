queryStringFilter <- function(req){
  qs <- req$QUERY_STRING
  args <- parseQS(qs)
  req$args <- c(req$args, args)
  forward()
}

#' @importFrom utils URLdecode
#' @noRd
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
  match <- stringi::stri_match_all(pathDef, regex="/<(\\.?[a-zA-Z][\\w_\\.]*)(:(int|double|numeric|bool|logical))?>")[[1]]
  names <- match[,2]
  type <- match[,4]
  if (length(names) <= 1 && is.na(names)){
    names <- character()
    type <- NULL
  }

  typedRe <- typeToRegex(type)
  re <- pathDef
  for (r in typedRe){
    repl <- paste0("/(", r, ")$2")
    re <- stringi::stri_replace_first_regex(re, pattern="/(<\\.?[a-zA-Z][\\w_\\.:]*>)(/?)",
                                          replacement=repl)
  }

  converters <- typeToConverters(type)

  list(names = names, regex = paste0("^", re, "$"), converters=converters)
}

typeToRegex <- function(type){
  re <- rep("[^\\\\./]+", length(type))
  re[type == "int"] <- "\\\\d+"
  re[type == "double" | type == "numeric"] <- "\\\\d*\\\\.?\\\\d*"
  re[type == "bool" | type == "logical"] <- "[01tfTF]|true|false|TRUE|FALSE"

  re
}

typeToConverters <- function(type){
  re <- NULL
  for (t in type){
    r <- function(x){x}

    if (!is.na(t)){
      if (t == "int"){
        r <- as.integer
      } else if (t == "double" || t == "numeric"){
        r <- as.numeric
      } else if (t == "bool" || t == "logical"){
        r <- as.logical
      }
    }
    re <- c(re, r)
  }
  re
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
