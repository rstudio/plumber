test_serializer <- function() {
  endpoint_serializer(
    serializer = function(value, req, res, errorHandler) {
      list(status=201L, headers=list(), body=as.character(value))
    },
    preexec_hook = function(req, res, data) {
      cat("preexec\n")
    },
    postexec_hook = function(value, req, res, data) {
      cat("postexec\n")
      value
    },
    aroundexec_hook = function(..., .next) {
      cat("around pre\n")
      value <- .next(...)
      cat("around post\n")
      value
    }
  )
}

#' @plumber
function(pr) {
  register_serializer("test_serializer", test_serializer)
}

#' @serializer test_serializer
#' @get /test_serializer
function() {
  cat("exec\n")
  4
}

#' Does not produce a plot
#' @serializer png
#' @get /no_plot
function(n = 100) {
  dt <- runif(n)
  # hist(dt)
  dt
}
