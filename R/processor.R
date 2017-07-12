#' A plumber processor
#' @include plumber.R
PlumberProcessor <- R6Class(
  "Processor",
  public = list(
    initialize = function(name, pre, post){
      private$preFun <- pre
      private$postFun <- post
      private$name <- name

      assign(name, self, envir=.globals$processors)
    },
    pre = function(...){
      do.call(private$preFun, getRelevantArgs(list(...), plumberExpression=private$preFun))
    },
    post = function(...){
      do.call(private$postFun, getRelevantArgs(list(...), plumberExpression=private$postFun))
    }
  ),
  private = list(
    preFun = NULL,
    postFun = NULL,
    data = NULL,
    name = NULL
  )
)
