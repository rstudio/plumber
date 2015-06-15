#' @export
forward <- function(){
  .globals$forwarded <- TRUE
}


RapierStep <- R6Class(
  "RapierStep",
  public = list(
    lines = NA,
    serializer = NULL,
    initialize = function(expr, envir, lines, serializer, processors){
      private$expr <- expr
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

      args <- getRelevantArgs(list(...), rapierExpression=private$expr)
      val <- do.call(eval(private$expr, envir=private$envir), args)

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
    processors = NULL
  )
)

getRelevantArgs <- function(args, rapierExpression){
  # positional list with names where they were provided.
  args

  if (length(args) == 0){
    unnamedArgs <- NULL
  } else if (is.null(names(args))){
    unnamedArgs <- 1:length(args)
  } else {
    unnamedArgs <- which(names(args) == "")
  }

  if (length(unnamedArgs) > 0 ){
    stop("Can't call a Rapier function with unnammed arguments. Missing names for argument(s) #",
         paste0(unnamedArgs, collapse=", "),
         ". Names of argument list was: \"",
         paste0(names(args), collapse=","), "\"")
  }

  # Extract the names of the arguments this function supports.
  fargs <- names(formals(eval(rapierExpression)))

  if (!"..." %in% fargs){
    # Use the named arguments that match, drop the rest.
    args <- args[names(args) %in% fargs]
  }

  args
}

RapierEndpoint <- R6Class(
  "RapierEndpoint",
  inherit = RapierStep,
  public = list(
    preempt = NA,
    verbs = NA,
    path = NA,
    canServe = function(req){
      #TODO: support non-identical paths
      req$REQUEST_METHOD %in% self$verbs && identical(req$PATH_INFO, self$path)
    },
    initialize = function(verbs, path, expr, envir, preempt, serializer, processors, lines){
      self$verbs <- verbs
      self$path <- path

      private$expr <- expr
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
    }
  )
)

RapierFilter <- R6Class(
  "RapierFilter",
  inherit = RapierStep,
  public = list(
    name = NA,
    initialize = function(name, expr, envir, serializer, processors, lines){
      self$name <- name
      private$expr <- expr
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
