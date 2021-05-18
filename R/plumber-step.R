
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
  inherit=Hookable,
  public = list(
    #' @field srcref from step block
    srcref = NULL,
    #' @field lines lines from step block
    lines = NA,
    #' @field serializer step serializer function
    serializer = NULL,
    #' @description Create a new [PlumberStep()] object
    #' @param expr step expr
    #' @param envir step environment
    #' @param lines step block
    #' @param serializer step serializer
    #' @param srcref `srcref` attribute from block
    #' @return A new `PlumberStep` object
    initialize = function(expr, envir, lines, serializer, srcref){
      private$expr <- expr
      if (is.expression(expr)) {
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      throw_if_func_is_not_a_function(private$func)
      private$envir <- envir

      if (!missing(srcref)) {
        self$srcref <- srcref
      }
      if (!missing(lines)){
        self$lines <- lines
      }

      if (!missing(serializer)){
        self$serializer <- serializer
      }
    },
    #' @description step execution function
    #' @param req,res Request and response objects created by a Plumber request
    exec = function(req, res) {
      hookEnv <- new.env(parent = emptyenv())

      # use a function as items could possibly be added to `req$args` in each step
      args_for_formal_matching <- function() {
        args <- c(
          # add in `req`, `res` as they have been removed from `req$args`
          list(req = req, res = res),
          req$args
        )
      }

      preexecStep <- function(...) {
        private$runHooks("preexec", c(list(data = hookEnv), args_for_formal_matching()))
      }
      execStep <- function(...) {
        private$runHooksAround("aroundexec", args_for_formal_matching(), .next = function(...) {
          relevant_args <- getRelevantArgs(list(...), func = private$func)
          do.call(private$func, relevant_args, envir = private$envir)
        })
      }
      postexecStep <- function(value, ...) {
        private$runHooks("postexec", c(list(data = hookEnv, value = value), args_for_formal_matching()))
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
    registerHook = function(stage=c("preexec", "postexec", "aroundexec"), handler){
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
getRelevantArgs <- function(args, func) {
  # Extract the names of the arguments this function supports.
  fargs <- names(formals(func))

  if (length(fargs) == 0) {
    # no matches
    return(list())
  }

  # fast return
  # also works with unnamed arguments
  if (identical(fargs, "...")) {
    return(args)
  }

  # If only req and res are found in function definition...
  # Only call using the first matches of req and res.
  if (all(fargs %in% c("req", "res"))) {
    ret <- list()
    # using `$` will retrieve the 1st occurance of req,res
    # args$req <- req is used within `Plumber$route()`
    if ("req" %in% fargs) {
      ret$req <- args$req
    }
    if ("res" %in% fargs) {
      ret$res <- args$res
    }
    return(ret)
  }

  # The remaining code MUST work with unnamed arguments
  # If there is no `...`, then the unnamed args will not be in `fargs` and will be removed
  # If there is `...`, then the unnamed args will not be in `fargs` and will be passed through

  if (!("..." %in% fargs)) {
    # Use the named arguments that match, drop the rest.
    args <- args[names(args) %in% fargs]
  }

  # dedupe matched formals
  arg_names <- names(args)
  is_farg <- arg_names %in% fargs
  # keep only the first matched formal argument (and all other non-`farg` params)
  args <- args[(is_farg & !duplicated(arg_names)) | (!is_farg)]

  args
}

#' Plumber Endpoint
#'
#' Defines a terminal handler in a Plumber router.
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
    #' @field description endpoint description
    description = NA,
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
    #' @template pr_setParsers__parsers
    #' @param srcref `srcref` attribute from block
    #' @param lines Endpoint block
    #' @param params Endpoint params
    #' @param comments,description,responses,tags Values to be used within the OpenAPI Spec
    #' @details Parameters values are obtained from parsing blocks of lines in a plumber file.
    #' They can also be provided manually for historical reasons.
    #' @return A new `PlumberEndpoint` object
    initialize = function(verbs, path, expr, envir, serializer, parsers, lines, params, comments, description, responses, tags, srcref) {

      self$verbs <- verbs

      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      throw_if_func_is_not_a_function(private$func)
      private$envir <- envir

      self$setPath(path)

      if (!missing(serializer) && !is.null(serializer)){
        self_set_serializer(self, serializer)
      }

      if (!missing(parsers) && !is.null(parsers)) {
        self$parsers <- make_parser(parsers)
      }
      if (!missing(srcref)) {
        self$srcref <- srcref
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
      if (!missing(description)){
        self$description <- description
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
    #' @description retrieve endpoint function
    getFunc = function() {
      private$func
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
    },
    # It would not make sense to have `$getPath()` and deprecate `$path`
    #' @description Updates `$path` with a sanitized `path` and updates the internal path meta-data
    #' @param path Path to set `$path`. If missing a beginning slash, one will be added.
    setPath = function(path) {
      if (substr(path, 1,1) != "/") {
        path <- paste0("/", path)
      }
      # private$func is not updated after initialization
      self$path <- path
      private$regex <- createPathRegex(path, self$getFuncParams())
      path
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
    initialize = function(name, expr, envir, serializer, lines, srcref){
      self$name <- name
      private$expr <- expr
      if (is.expression(expr)){
        private$func <- eval(expr, envir)
      } else {
        private$func <- expr
      }
      throw_if_func_is_not_a_function(private$func)
      private$envir <- envir

      if (!missing(serializer)){
        self_set_serializer(self, serializer)
      }
      if (!missing(srcref)) {
        self$srcref <- srcref
      }
      if (!missing(lines)){
        self$lines <- lines
      }
    }
  )
)


throw_if_func_is_not_a_function <- function(func) {
  if(!is.function(func)) {
    stop("`expr` did not evaluate to a function")
  }
}
