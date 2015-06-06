default404Handler <- function(req, res){
  res$status <- 404
  res$setHeader("Conte-Type", "text/html")
  res$body <- "404 - Resource Not Found"
}

defaultErrorHandler <-function(req, res, err){
  print(err)
  stop ("Error Handler not implemented!")
}
