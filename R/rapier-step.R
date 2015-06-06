#' @export
forward <- function(){
  .globals$forwarded <- TRUE
}


RapierStep <- R6Class(
  "RapierStep",
  public = list(
    lines = NA,
    serializer = NULL,
    initialize = function(expr, envir, lines, serializer){
      private$expr <- expr
      private$envir <- envir

      if (!missing(lines)){
        self$lines <- lines
      }

      if (!missing(serializer)){
        self$serializer <- serializer
      }
    },
    exec = function(...){
      # positional list with names where they were provided.
      args <- list(...)

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
      fargs <- names(formals(eval(private$expr)))

      if (!"..." %in% fargs){
        # Use the named arguments that match, drop the rest.
        args <- args[names(args) %in% fargs]
      }

      do.call(eval(private$expr, envir=private$envir), args)
    }
  ),
  private = list(
    envir = NA,
    expr = NA
  )
)

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
    initialize = function(verbs, path, expr, envir, preempt, serializer, lines){
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
    }
  )
)

RapierFilter <- R6Class(
  "RapierFilter",
  inherit = RapierStep,
  public = list(
    name = NA,
    initialize = function(name, expr, envir, serializer, lines){
      self$name <- name
      private$expr <- expr
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
