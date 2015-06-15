#' @include rapier.R
RapierProcessor <- R6Class(
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

      do.call(private$preFun, getRelevantArgs(dat, rapierExpression=private$preFun))
    },
    post = function(value, ...){
      dat <- c(list(data=private$data, value=value), ...)

      do.call(private$postFun, getRelevantArgs(dat, rapierExpression=private$postFun))
    }
  ),
  private = list(
    preFun = NULL,
    postFun = NULL,
    data = NULL,
    name = NULL
  )
)
