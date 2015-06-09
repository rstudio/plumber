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
    pre = function(req, res){
      private$preFun(req = req, res = res, data = private$data)
    },
    post = function(val, req, res){
      private$postFun(req = req, res = res, data = private$data, val = val)
    }
  ),
  private = list(
    preFun = NULL,
    postFun = NULL,
    data = NULL,
    name = NULL
  )
)

RapierProcessor$new(
  "jpeg",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    jpeg(t)
  },
  function(val, req, res, data){
    dev.off()

    # read base64 file
    base64enc::base64decode(file(data$file))
  }
)

RapierProcessor$new(
  "png",
  function(req, res, data){
    t <- tempfile()
    data$file <- t
    png(t)
  },
  function(val, req, res, data){
    dev.off()

    # read base64 file
    base64enc::base64decode(file(data$file))
  }
)
