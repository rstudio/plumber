
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

#' plumber step R6 class
#' @description an object representing a step in the lifecycle of the treatment
#' of a request by a plumber router.
PlumberStep <- R6Class(
  "PlumberStep",
  inherit=hookable,
  public = list(
    #' @field lines lines from step block
    lines = NA,
    #' @field serializer step serializer function
    serializer = NULL,
    #' @description Create a new [PlumberStep()] object
    #' @param expr step expr
    #' @param envir step environment
    #' @param lines step block
    #' @param serializer step serializer
    #' @return A new `PlumberStep` object
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
    #' @description step execution function
    #' @param ... additional arguments for step execution
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
    #' @description step hook registration method
    #' @param stage a character string.
    #' @param handler a step handler function.
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
#' @export
PlumberEndpoint <- R6Class(
  "PlumberEndpoint",
  inherit = PlumberStep,
  public = list(
    #' @field verbs a character vector. http methods. For historical reasons we have
    #' to accept multiple verbs for a single path. Now it's simpler to just parse
    #' each separate verb/path into its own endpoint, so we just do that.
    verbs = NA,
    #' @field path a character string. endpoint path
    path = NA,
    #' @field comments endpoint comments
    comments = NA,
    #' @field responses endpoint responses
    responses = NA,
    #' @description retrieve endpoint typed parameters
    getTypedParams = function(){
      data.frame(name = private$regex$names,
                 type = private$regex$types,
                 isArray = private$regex$areArrays,
                 stringsAsFactors = FALSE)
    },
    #' @field params endpoint parameters
    params = NA,
    #' @field tags endpoint tags
    tags = NA,
    #' @description ability to serve request
    #' @param req a request object
    #' @return a logical. `TRUE` when endpoint can serve request.
    canServe = function(req){
      req$REQUEST_METHOD %in% self$verbs && !is.na(stri_match_first_regex(req$PATH_INFO, private$regex$regex)[1,1])
    },
    #' @description Create a new `PlumberEndpoint` object
    #' @param verbs endpoint verb
    #' @param path endpoint path
    #' @param expr endpoint expr
    #' @param envir endpoint environment
    #' @param serializer endpoint serializer
    #' @param lines endpoint block
    #' @param params endpoint params
    #' @param comments endpoint comments
    #' @param responses endpoint responses
    #' @param tags endpoint tags
    #' @details Parameters values are obtained from parsing blocks of lines in a plumber file.
    #' They can also be provided manually for historical reasons.
    #' @return A new `PlumberEndpoint` object
    initialize = function(verbs, path, expr, envir, serializer, lines, params, comments, responses, tags){
      self$verbs <- verbs
      self$path <- path

      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      private$envir <- envir

      private$regex <- createPathRegex(path, self$getFuncParams())

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
    #' @description retrieve endpoint path parameters
    #' @param path endpoint path
    getPathParams = function(path){
      extractPathParams(private$regex, path)
    },
    #' @description retrieve endpoint expression parameters
    getFuncParams = function() {
      getArgsMetadata(private$func)
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
