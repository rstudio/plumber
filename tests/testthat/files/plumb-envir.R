foo <- TRUE
#* @post /test
#' @serializer json list(simplifyVector=foo)
function() {}

bar <- list(simplifyVector=TRUE)
#* @post /test2
#' @serializer json bar
function() {}
