
library(stringi)

#' @preempt auth
#' @use /
function(){
  list(msg="Welcome to the root URL!")
}

#' @filter auth
function(req, res){
  if (!stri_startswith_fixed(req$QUERY_STRING, "?user=")){
    # Don't continue
    stop("Unauthenticated")
  }

  user <- substr(req$QUERY_STRING, 6, nchar(req$QUERY_STRING))
  res$username <- user

  forward()
}

#' @get /me
function(req, res){
  list(name=res$username)
}
