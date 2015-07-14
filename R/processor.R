#' @include plumbr.R
PlumbrProcessor <- R6Class(
  "Processor",
  public = list(
    initialize = function(name, pre, post){
      private$preFun <- pre
      private$postFun <- post
      private$name <- name
      private$data <- new.env()

      .globals$processors[[name]] <<- self
    },
    pre = function(...){
      dat <- c(list(data=private$data), ...)

      do.call(private$preFun, getRelevantArgs(dat, plumbrExpression=private$preFun))
    },
    post = function(value, ...){
      dat <- c(list(data=private$data, value=value), ...)

      do.call(private$postFun, getRelevantArgs(dat, plumbrExpression=private$postFun))
    }
  ),
  private = list(
    preFun = NULL,
    postFun = NULL,
    data = NULL,
    name = NULL
  )
)
