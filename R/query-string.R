queryStringParser <- function(req, res){
  qs <- req$QUERY_STRING
  parseQS(qs)
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
  keys <- sapply(kv, "[[", 1)

  keys <- unname(sapply(keys, URLdecode))
  vals <- sapply(kv, "[[", 2)
  vals[is.na(vals)] <- ""
  vals <- unname(sapply(vals, URLdecode))

  ret <- as.list(vals)
  names(ret) <- keys

  ret
}
