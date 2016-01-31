#' A plumber processor
#' @include plumber.R
PlumberProcessor <- R6Class(
  "Processor",
  public = list(
    initialize = function(name, pre, post){
      private$preFun <- pre
      private$postFun <- post
      private$name <- name
      private$data <- new.env()

      assign(name, self, envir=.globals$processors)
    },
    pre = function(...){
      dat <- c(list(data=private$data), ...)

      do.call(private$preFun, getRelevantArgs(dat, plumberExpression=private$preFun))
    },
    post = function(value, ...){
      dat <- c(list(data=private$data, value=value), ...)

      do.call(private$postFun, getRelevantArgs(dat, plumberExpression=private$postFun))
    }
  ),
  private = list(
    preFun = NULL,
    postFun = NULL,
    data = NULL,
    name = NULL
  )
)
