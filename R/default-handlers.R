default404Handler <- function(req, res){
  res$status <- 404
  res$setHeader("Content-Type", "text/html")
  res$body <- "404 - Resource Not Found"
}

defaultErrorHandler <-function(req, res, err){
  print(err)
  res$status <- 500

  res$body <- "500 - Internal server error"

  if (.globals$debug){
    res$body <- paste(res$body, err, sep="\n")
  }
}
