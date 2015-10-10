#' Forward Request to The Next Handler
#'
#' This function is used when a filter is done processing a request and wishes
#' to pass control off to the next handler in the chain. If this is not called
#' by a filter, the assumption is that the filter fully handled the request
#' itself and no other filters or endpoints should be evaluated for this
#' request.
#' @export
forward <- function(){
  .globals$forwarded <- TRUE
}


PlumberStep <- R6Class(
  "PlumberStep",
  public = list(
    lines = NA,
    serializer = NULL,
    initialize = function(expr, envir, lines, serializer, processors){
      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }

      private$envir <- envir

      if (!missing(lines)){
        self$lines <- lines
      }

      if (!missing(serializer)){
        self$serializer <- serializer
      }

      if (!missing(processors)){
        private$processors <- processors
      }
    },
    exec = function(...){
      for (p in private$processors){
        p$pre(...)
      }

      args <- getRelevantArgs(list(...), plumberExpression=private$expr)
      val <- do.call(private$func, args)

      for (p in private$processors){
        li <- c(list(value=val), ...)
        val <- do.call(p$post, li)
      }

      val
    }
  ),
  private = list(
    envir = NA,
    expr = NA,
    func = NA,
    processors = NULL
  )
)

# @param positional list with names where they were provided.
getRelevantArgs <- function(args, plumberExpression){
  if (length(args) == 0){
    unnamedArgs <- NULL
  } else if (is.null(names(args))){
    unnamedArgs <- 1:length(args)
  } else {
    unnamedArgs <- which(names(args) == "")
  }

  if (length(unnamedArgs) > 0 ){
    stop("Can't call a Plumber function with unnammed arguments. Missing names for argument(s) #",
         paste0(unnamedArgs, collapse=", "),
         ". Names of argument list was: \"",
         paste0(names(args), collapse=","), "\"")
  }

  # Extract the names of the arguments this function supports.
  fargs <- names(formals(eval(plumberExpression)))

  if (!"..." %in% fargs){
    # Use the named arguments that match, drop the rest.
    args <- args[names(args) %in% fargs]
  }

  args
}

PlumberEndpoint <- R6Class(
  "PlumberEndpoint",
  inherit = PlumberStep,
  public = list(
    preempt = NA,
    verbs = NA,
    path = NA,
    canServe = function(req){
      req$REQUEST_METHOD %in% self$verbs && !is.na(stringi::stri_match(req$PATH_INFO, regex=private$regex$regex)[1,1])
    },
    initialize = function(verbs, path, expr, envir, preempt, serializer, processors, lines){
      self$verbs <- verbs
      self$path <- path

      private$regex <- createPathRegex(path)

      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      private$envir <- envir

      if (!missing(preempt) && !is.null(preempt)){
        self$preempt <- preempt
      }
      if (!missing(serializer) && !is.null(serializer)){
        self$serializer <- serializer
      }
      if (!missing(lines)){
        self$lines <- lines
      }
      if (!missing(processors)){
        private$processors <- processors
      }
    },
    getPathParams = function(path){
      extractPathParams(private$regex, path)
    }
  ),
  private = list(
    regex = NULL
  )
)

PlumberFilter <- R6Class(
  "PlumberFilter",
  inherit = PlumberStep,
  public = list(
    name = NA,
    initialize = function(name, expr, envir, serializer, processors, lines){
      self$name <- name
      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      private$envir <- envir

      if (!missing(serializer)){
        self$serializer <- serializer
      }
      if (!missing(lines)){
        self$lines <- lines
      }
      if (!missing(processors)){
        private$processors <- processors
      }
    }
  )
)
