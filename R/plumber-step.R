
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
getRelevantArgs <- function(args, plumberExpression) {
  if (length(args) == 0) {
    unnamedArgs <- NULL
  } else if (is.null(names(args))) {
    unnamedArgs <- 1:length(args)
  } else {
    unnamedArgs <- which(names(args) == "")
  }

  if (length(unnamedArgs) > 0 ) {
    stop("Can't call a Plumber function with unnammed arguments. Missing names for argument(s) #",
         paste0(unnamedArgs, collapse=", "),
         ". Names of argument list was: \"",
         paste0(names(args), collapse=","), "\"")
  }

  # Extract the names of the arguments this function supports.
  fargs <- names(formals(eval(plumberExpression)))

  if (length(fargs) == 0) {
    # no matches
    return(list())
  }

  # If only req and res are found in function definition...
  # Only call using the first matches of req and res.
  #   This allows for post body content to have `req` and `res` named arguments and not duplicated values cause issues.
  if (all(fargs %in% c("req", "res"))) {
    ret <- list()
    # using `$` will retrieve the 1st occurance of req,res
    # args$req <- req is used within `plumber$route()`
    if ("req" %in% fargs) {
      ret$req <- args$req
    }
    if ("res" %in% fargs) {
      ret$res <- args$res
    }
    return(ret)
  }

  if (!"..." %in% fargs) {
    # Use the named arguments that match, drop the rest.
    args <- args[names(args) %in% fargs]
  }

  # for all args, check if they are duplicated
  arg_names <- names(args)
  matched_arg_names <- arg_names[arg_names %in% fargs]
  duplicated_matched_arg_names <- duplicated(matched_arg_names, fromLast = TRUE)

  if (any(duplicated_matched_arg_names)) {
    stop(
      "Can't call a Plumber function with duplicated matching formal arguments: ",
      paste0(unique(matched_arg_names[duplicated_matched_arg_names]), collapse = ", "),
      "\nPlumber recommends that the route's function signature be `function(req, res)`",
      "\nand to access arguments via `req$args`, `req$argsPath`, `req$argsPostBody`, or `req$argsQuery`."
    )
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
    getTypedParams = function() {
      data.frame(
        name = private$regex$names,
        type = private$regex$types,
        isArray = private$regex$areArrays,
        stringsAsFactors = FALSE
      )
    },
    #' @field params endpoint parameters
    params = NA,
    #' @field tags endpoint tags
    tags = NA,
    #' @field parsers step allowed parsers
    parsers = NULL,
    #' @description ability to serve request
    #' @param req a request object
    #' @return a logical. `TRUE` when endpoint can serve request.
    canServe = function(req) {
      req$REQUEST_METHOD %in% self$verbs && self$matchesPath(req$PATH_INFO)
    },
    #' @description determines if route matches requested path
    #' @param path a url path
    #' @return a logical. `TRUE` when endpoint matches the requested path.
    matchesPath = function(path) {
      !is.na(stri_match_first_regex(path, private$regex$regex)[1,1])
    },
    #' @description Create a new `PlumberEndpoint` object
    #' @param verbs Endpoint verb Ex: `"GET"`, `"POST"`
    #' @param path Endpoint path. Ex: `"/index.html"`, `"/foo/bar/baz"`
    #' @param expr Endpoint function or expression that evaluates to a function.
    #' @param envir Endpoint environment
    #' @param serializer Endpoint serializer. Ex: [serializer_json()]
    #' @template pr_set_parsers__parsers
    #' @param lines Endpoint block
    #' @param params Endpoint params
    #' @param comments,responses,tags Values to be used within the OpenAPI Spec
    #' @details Parameters values are obtained from parsing blocks of lines in a plumber file.
    #' They can also be provided manually for historical reasons.
    #' @return A new `PlumberEndpoint` object
    initialize = function(verbs, path, expr, envir, serializer, parsers, lines, params, comments, responses, tags) {
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
        self_set_serializer(self, serializer)
      }

      if (!missing(parsers) && !is.null(parsers)) {
        self$parsers <- make_parser(parsers)
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
    },
    #' @description retrieve endpoint defined parameters
    getEndpointParams = function() {
      if (length(self$params) == 0) {
        return(list())
      }
      if (isTRUE(is.na(self$params))) {
        return(list())
      }
      self$params
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
        self_set_serializer(self, serializer)
      }
      if (!missing(lines)){
        self$lines <- lines
      }
    }
  )
)
