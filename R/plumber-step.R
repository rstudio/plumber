
forward_class <- "plumber_forward"
#' Forward Request to The Next Handler
#'
#' This function is used when a filter is done processing a request and wishes
#' to pass control off to the next handler in the chain. If this is not called
#' by a filter, the assumption is that the filter fully handled the request
#' itself and no other filters or endpoints should be evaluated for this
#' request.
#' @export
forward <- function() {
  exec <- getCurrentExec()
  exec$forward <- TRUE
}
hasForwarded <- function() {
  getCurrentExec()$forward
}
resetForward <- function() {
  exec <- getCurrentExec()
  exec$forward <- FALSE
}

PlumberStep <- R6Class(
  "PlumberStep",
  inherit=hookable,
  public = list(
    lines = NA,
    serializer = NULL,
    initialize = function(expr, envir, lines, serializer){
      private$expr <- expr
      if (is.expression(expr)) {
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
    exec = function(...) {
      allArgs <- list(...)
      args <- getRelevantArgs(allArgs, plumberExpression=private$func)

      hookEnv <- new.env()

      preexecStep <- function(...) {
        private$runHooks("preexec", c(list(data = hookEnv), allArgs))
      }
      execStep <- function(...) {
        do.call(private$func, args, envir = private$envir)
      }
      postexecStep <- function(value, ...) {
        private$runHooks("postexec", c(list(data = hookEnv, value = value), allArgs))
      }
      runSteps(
        NULL,
        function(error) {
          # rethrow error
          stop(error)
        },
        list(
          preexecStep,
          execStep,
          postexecStep
        )
      )
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

#' Plumber Endpoint
#'
#' Defines a terminal handler in a PLumber router.
#'
#' @importFrom stringi stri_match_first_regex
#' @export
PlumberEndpoint <- R6Class(
  "PlumberEndpoint",
  inherit = PlumberStep,
  public = list(
    verbs = NA,
    path = NA,
    comments = NA,
    responses = NA,
    getTypedParams = function(){
      data.frame(name=private$regex$names, type=private$regex$types, stringsAsFactors = FALSE)
    },
    params = NA,
    tags = NA,
    canServe = function(req){
      req$REQUEST_METHOD %in% self$verbs && !is.na(stri_match_first_regex(req$PATH_INFO, private$regex$regex)[1,1])
    },
    # For historical reasons we have to accept multiple verbs for a single path. Now it's simpler
    # to just parse each separate verb/path into its own endpoint, so we just do that.
    initialize = function(verbs, path, expr, envir, serializer, lines, params, comments, responses, tags){
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
      if(!missing(tags) && !is.null(tags)){
        # make sure we box tags in json using I()
        # single tags should be converted to json as:
        # tags: ["tagName"] and not tags: "tagName"
        self$tags <- I(tags)
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
