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
  inherit=hookable,
  public = list(
    lines = NA,
    serializer = NULL,
    initialize = function(expr, envir, lines, serializer){
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
    },
    exec = function(...){
      args <- getRelevantArgs(list(...), plumberExpression=private$expr)

      hookEnv <- new.env()

      private$runHooks("preexec", c(list(data=hookEnv), list(...)))
      val <- do.call(private$func, args, envir=private$envir)
      private$runHooks("postexec", c(list(data=hookEnv, value=val), list(...)))
    },
    registerHook = function(stage=c("preexec", "postexec"), handler){
      stage <- match.arg(stage)
      super$registerHook(stage, handler)
    }
  ),
  private = list(
    envir = NA,
    expr = NA,
    func = NA
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
    verbs = NA,
    path = NA,
    comments = NA,
    responses = NA,
    getTypedParams = function(){
      data.frame(name=private$regex$names, type=private$regex$types)
    },
    params = NA,
    canServe = function(req){
      req$REQUEST_METHOD %in% self$verbs && !is.na(stringi::stri_match(req$PATH_INFO, regex=private$regex$regex)[1,1])
    },
    initialize = function(verbs, path, expr, envir, serializer, lines, params, comments, responses){
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

      if (!missing(serializer) && !is.null(serializer)){
        self$serializer <- serializer
      }
      if (!missing(lines)){
        self$lines <- lines
      }
      if (!missing(params)){
        self$params <- params
      }
      if (!missing(comments)){
        self$comments <- comments
      }
      if (!missing(responses)){
        self$responses <- responses
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
    initialize = function(name, expr, envir, serializer, lines){
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
    }
  )
)
