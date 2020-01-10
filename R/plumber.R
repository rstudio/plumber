#' @import R6
#' @import stringi
NULL

# used to identify annotation flags.
verbs <- c("GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS", "PATCH")
enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(verbs)
  }
  toupper(v)
}

#' @rdname plumber
#' @export
plumb <- function(file, dir="."){

  dirMode <- NULL

  if (!missing(file) && !missing(dir)){
    # Both were explicitly set. Error
    stop("You must set either the file or the directory parameter, not both")

  } else if (missing(file)){
    if (identical(dir, "")){
      # dir and file are both empty. Error
      stop("You must specify either a file or directory parameter")
    }

    # Parse dir
    dirMode <- TRUE
    dir <- sub("/$", "", dir)

    # Find plumber.R in the directory case-insensitively
    file <- list.files(dir, "^plumber\\.r$", ignore.case = TRUE, full.names = TRUE)
    if (length(file) == 0){
      stop("No plumber.R file found in the specified directory: ", dir)
    }

  } else {
    # File was specified
    dirMode <- FALSE
  }

  entrypoint <- list.files(dir, "^entrypoint\\.r$", ignore.case = TRUE)
  if (dirMode && length(entrypoint) > 0){
    # Dir was specified and we found an entrypoint.R

    old <- setwd(dir)
    on.exit(setwd(old))

    # Expect that entrypoint will provide us with the router
    #   Do not 'poison' the global env. Using a local environment
    #   sourceUTF8 returns the (visible) value object. No need to call source()$value()
    pr <- sourceUTF8(entrypoint, environment())

    if (!inherits(pr, "plumber")){
      stop("entrypoint.R must return a runnable Plumber router.")
    }

    pr
  } else if (file.exists(file)) {
    # Plumber file found

    plumber$new(file)
  } else {
    # Couldn't find the Plumber file nor an entrypoint
    stop("File does not exist: ", file)
  }
}


#' @include query-string.R
#' @include post-body.R
#' @include cookie-parser.R
#' @include shared-secret-filter.R
defaultPlumberFilters <- list(
  queryString = queryStringFilter,
  postBody = postBodyFilter,
  cookieParser = cookieFilter,
  sharedSecret = sharedSecretFilter)

hookable <- R6Class(
  "hookable",
  public=list(
    registerHook = function(stage, handler){
      private$hooks[[stage]] <- c(private$hooks[[stage]], handler)
    },
    registerHooks = function(handlers){
      for (i in 1:length(handlers)){
        stage <- names(handlers)[i]
        h <- handlers[[i]]

        self$registerHook(stage, h)
      }
    }
  ), private=list(
    hooks = list( ),

    # Because we're passing in a `value` argument here, `runHooks` will return either the
    # unmodified `value` argument back, or will allow one or more hooks to modify the value,
    # in which case the modified value will be returned. Hooks declare that they intend to
    # modify the value by accepting a parameter named `value`, in which case their returned
    # value will be used as the updated value.
    runHooks = function(stage, args) {
      if (missing(args)) {
        args <- list()
      }

      stageHooks <- private$hooks[[stage]]
      if (length(stageHooks) == 0) {
        # if there is nothing to execute, return early
        return(args$value)
      }

      runSteps(
        NULL,
        errorHandlerStep = stop,
        append(
          unlist(lapply(stageHooks, function(stageHook) {
            stageHookArgs <- list()
            list(
              function(...) {
                stageHookArgs <<- getRelevantArgs(args, plumberExpression = stageHook)
              },
              function(...) {
                do.call(stageHook, stageHookArgs) #TODO: envir=private$envir?
              },
              # `do.call` could return a promise. Wait for it's return value
              # if "value" exists in the original args, overwrite it for futher execution
              function(value, ...) {
                if ("value" %in% names(stageHookArgs)) {
                  # Special case, retain the returned value from the hook
                  # and pass it in as the value for the next handler.
                  # Ultimately, return value from this function
                  args$value <<- value
                }
                NULL
              }
            )
          })),
          list(
            function(...) {
              # Return the value as passed in or as explcitly modified by one or more hooks.
              return(args$value)
            }
          )
        )
      )
    }
  )
)


#' Plumber Router
#'
#' Routers are the core request handler in plumber. A router is responsible for
#' taking an incoming request, submitting it through the appropriate filters and
#' eventually to a corresponding endpoint, if one is found.
#'
#' See \url{http://www.rplumber.io/docs/programmatic/} for additional
#' details on the methods available on this object.
#' @param file The file to parse as the plumber router definition
#' @param dir The directory containing the `plumber.R` file to parse as the
#'   plumber router definition. Alternatively, if an `entrypoint.R` file is
#'   found, it will take precedence and be responsible for returning a runnable
#'   Plumber router.
#' @include globals.R
#' @include serializer-json.R
#' @include parse-block.R
#' @include parse-globals.R
#' @export
#' @importFrom httpuv runServer
#' @import crayon
plumber <- R6Class(
  "plumber",
  inherit = hookable,
  public = list(
    initialize = function(file=NULL, filters=defaultPlumberFilters, envir){

      if (!is.null(file)){
        if (!file.exists(file)){
          stop("File does not exist: ", file)
        } else {
          inf <- file.info(file)
          if (inf$isdir){
            stop("Expecting a file but found a directory: '", file, "'.")
          }
        }
      }

      if (missing(envir)){
        private$envir <- new.env(parent=.GlobalEnv)
      } else {
        private$envir <- envir
      }

      if (is.null(filters)){
        filters <- list()
      }

      # Initialize
      private$serializer <- serializer_json()
      private$errorHandler <- defaultErrorHandler()
      private$notFoundHandler <- default404Handler

      # Add in the initial filters
      for (fn in names(filters)){
        fil <- PlumberFilter$new(fn, filters[[fn]], private$envir, private$serializer, NULL)
        private$filts <- c(private$filts, fil)
      }

      if (!is.null(file)){
        private$lines <- readUTF8(file)
        private$parsed <- parseUTF8(file)

        for (i in 1:length(private$parsed)){
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]][c(1,3)]

          evaluateBlock(srcref, private$lines, e, private$envir, private$addEndpointInternal,
                        private$addFilterInternal, private$setErrorHandlerInternal, self$mount)
        }

        private$globalSettings <- parseGlobals(private$lines)
      }

    },
    run = function(
      host = '127.0.0.1',
      port = getOption('plumber.port'),
      swagger = interactive(),
      debug = interactive(),
      swaggerCallback = getOption('plumber.swagger.url', NULL)
    ) {
      port <- findPort(port)


      message("Running plumber API at ", urlHost(host, port, changeHostLocation = FALSE))

      priorDebug <- getOption("plumber.debug")
      on.exit({ options("plumber.debug" = priorDebug) })
      options("plumber.debug" = debug)

      # Set and restore the wd to make it appear that the proc is running local to the file's definition.
      if (!is.null(private$filename)){
        cwd <- getwd()
        on.exit({ setwd(cwd) }, add = TRUE)
        setwd(dirname(private$filename))
      }

      if (isTRUE(swagger) || is.function(swagger)) {
        if (!requireNamespace("swagger")) {
          stop("swagger must be installed for the Swagger UI to be displayed")
        }
        spec <- self$swaggerFile()

        # Create a function that's hardcoded to return the swaggerfile -- regardless of env.
        swagger_fun <- function(req, res, ..., scheme = "deprecated", host = "deprecated", path = "deprecated") {
          if (!missing(scheme) || !missing(host) || !missing(path)) {
            warning("`scheme`, `host`, or `path` are not supported to produce swagger.json")
          }
          # allows swagger-ui to provide proper callback location given the referrer location
          # ex: rstudio cloud
          # use the HTTP_REFERER so RSC can find the swagger location to ask
          ## (can't directly ask for 127.0.0.1)
          referrer_url <- req$HTTP_REFERER
          referrer_url <- sub("index\\.html$", "", referrer_url)
          referrer_url <- sub("__swagger__/$", "", referrer_url)
          spec$servers <- list(
            list(
              url = referrer_url,
              description = "OpenAPI"
            )
          )

          if (is.function(swagger)) {
            # allow users to update the swagger file themselves
            ret <- swagger(self, spec, ...)
            # Since users could have added more NA or NULL values...
            ret <- removeNaOrNulls(ret)
          } else {
            # NA/NULL values already removed
            ret <- spec
          }
          ret
        }
        # https://swagger.io/specification/#document-structure
        # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json or openapi.yaml."
        self$handle("GET", "/openapi.json", swagger_fun, serializer = serializer_unboxed_json())
        # keeping for legacy purposes
        self$handle("GET", "/swagger.json", swagger_fun, serializer = serializer_unboxed_json())

        swagger_index <- function(...) {
          swagger::swagger_spec(
            'window.location.origin + window.location.pathname.replace(/\\(__swagger__\\\\/|__swagger__\\\\/index.html\\)$/, "") + "openapi.json"',
            version = "3"
          )
        }
        for (path in c("/__swagger__/index.html", "/__swagger__/")) {
          self$handle(
            "GET", path, swagger_index,
            serializer = serializer_html()
          )
        }
        self$mount("/__swagger__", PlumberStatic$new(swagger::swagger_path()))

        swaggerUrl <- paste0(
          urlHost(getOption("plumber.apiHost", host), port, changeHostLocation = TRUE),
          "/__swagger__/"
        )
        message("Running Swagger UI  at ", swaggerUrl, sep = "")
        # notify swaggerCallback of plumber swagger location
        if (!is.null(swaggerCallback) && is.function(swaggerCallback)) {
          swaggerCallback(swaggerUrl)
        }
      }

      on.exit(private$runHooks("exit"), add = TRUE)

      httpuv::runServer(host, port, self)
    },
    mount = function(path, router){
      # Ensure that the path has both a leading and trailing slash.
      if (!startsWith(path, "/")) {
        path <- paste0("/", path)
      }
      if (!endsWith(path, "/")) {
        path <- paste0(path, "/")
      }

      private$mnts[[path]] <- router
    },
    registerHook = function(stage=c("preroute", "postroute",
                                    "preserialize", "postserialize", "exit"), handler){
      stage <- match.arg(stage)
      super$registerHook(stage, handler)
    },

    handle = function(methods, path, handler, preempt, serializer, endpoint, ...){
      epdef <- !missing(methods) || !missing(path) || !missing(handler) || !missing(serializer)
      if (!missing(endpoint) && epdef){
        stop("You must provide either the components for an endpoint (handler and serializer) OR provide the endpoint yourself. You cannot do both.")
      }

      if (epdef){
        if (missing(serializer)){
          serializer <- private$serializer
        }

        endpoint <- PlumberEndpoint$new(methods, path, handler, private$envir, serializer, ...)
      }
      private$addEndpointInternal(endpoint, preempt)
    },
    print = function(prefix="", topLevel=TRUE, ...){
      endCount <- as.character(sum(unlist(lapply(self$endpoints, length))))

      # Reference on box characters: https://en.wikipedia.org/wiki/Box-drawing_character

      cat(prefix)
      if (!topLevel){
        cat("\u2502 ") # "| "
      }
      cat(crayon::silver("# Plumber router with ", endCount, " endpoint", ifelse(endCount == 1, "", "s"),", ",
                         as.character(length(private$filts)), " filter", ifelse(length(private$filts) == 1, "", "s"),", and ",
                         as.character(length(self$mounts)), " sub-router", ifelse(length(self$mounts) == 1, "", "s"),".\n", sep=""))

      if(topLevel){
        cat(prefix, crayon::silver("# Call run() on this object to start the API.\n"), sep="")
      }

      # Filters
      # TODO: scrub internal filters?
      for (f in private$filts){
        cat(prefix, "\u251c\u2500\u2500", crayon::green("[", f$name, "]", sep=""), "\n", sep="") # "+--"
      }

      paths <- self$routes

      printEndpoints <- function(prefix, name, nodes, isLast){
        if (is.list(nodes)){
          verbs <- paste(sapply(nodes, function(n){ n$verbs }), collapse=", ")
        } else {
          verbs <- nodes$verbs
        }
        cat(prefix)
        if (isLast){
          cat("\u2514") # "|_"
        } else {
          cat("\u251c")  # "+"
        }
        cat(crayon::blue("\u2500\u2500/", name, " (", verbs, ")\n", sep=""), sep="") # "+--"
      }

      printNode <- function(node, name="", prefix="", isRoot=FALSE, isLast = FALSE){

        childPref <- paste0(prefix, "\u2502  ")
        if (isRoot){
          childPref <- prefix
        }

        if (is.list(node)){
          if (is.null(names(node))) {
            # This is a list of Plumber endpoints all mounted at this location. Collapse
            printEndpoints(prefix, name, node, isLast)
          } else{
            # It's a list of other stuff.
            if (!isRoot){
              cat(prefix, "\u251c\u2500\u2500/", name, "\n", sep="") # "+--"
            }
            for (i in 1:length(node)){
              name <- names(node)[i]
              printNode(node[[i]], name, childPref, isLast = i == length(node))
            }
          }
        } else if (inherits(node, "plumber")){
          cat(prefix, "\u251c\u2500\u2500/", name, "\n", sep="") # "+--"
          # It's a router, let it print itself
          print(node, prefix=childPref, topLevel=FALSE)
        } else if (inherits(node, "PlumberEndpoint")){
          printEndpoints(prefix, name, node, isLast)
        } else {
          cat("??")
        }
      }
      printNode(paths, "", prefix, TRUE)

      invisible(self)
    },

    serve = function(req, res) {
      hookEnv <- new.env()

      prerouteStep <- function(...) {
        private$runHooks("preroute", list(data = hookEnv, req = req, res = res))
      }
      routeStep <- function(...) {
        self$route(req, res)
      }
      postrouteStep <- function(value, ...) {
        private$runHooks("postroute", list(data = hookEnv, req = req, res = res, value = value))
      }

      serializeSteps <- function(value, ...) {
        if ("PlumberResponse" %in% class(value)) {
          return(res$toResponse())
        }

        ser <- res$serializer
        if (typeof(ser) != "closure") {
          stop("Serializers must be closures: '", ser, "'")
        }

        preserializeStep <- function(value, ...) {
          private$runHooks("preserialize", list(data = hookEnv, req = req, res = res, value = value))
        }
        serializeStep <- function(value, ...) {
          ser(value, req, res, private$errorHandler)
        }
        postserializeStep <- function(value, ...) {
          private$runHooks("postserialize", list(data = hookEnv, req = req, res = res, value = value))
        }

        runSteps(
          value,
          stop,
          list(
            preserializeStep,
            serializeStep,
            postserializeStep
          )
        )
      }

      errorHandlerStep <- function(error, ...) {
        # must set the body and return as this is after the serialize step
        res$body <- private$errorHandler(req, res, error)
        return(res$toResponse())
      }

      runSteps(
        NULL,
        errorHandlerStep,
        list(
          prerouteStep,
          routeStep,
          postrouteStep,
          serializeSteps
        )
      )

      #
      # conclude <- function(v) {
      #   v <- private$runHooks("postroute", list(data=hookEnv, req=req, res=res, value=v))
      #
      #   if ("PlumberResponse" %in% class(v)){
      #     # They returned the response directly, don't serialize.
      #     res$toResponse()
      #   } else {
      #     ser <- res$serializer
      #
      #     if (typeof(ser) != "closure") {
      #       stop("Serializers must be closures: '", ser, "'")
      #     }
      #
      #     v <- private$runHooks("preserialize", list(data=hookEnv, req=req, res=res, value=v))
      #     out <- ser(v, req, res, private$errorHandler)
      #     out <- private$runHooks("postserialize", list(data=hookEnv, req=req, res=res, value=out))
      #     out
      #   }
      # }
      #
      # if (hasPromises() && promises::is.promise(val)){
      #   # The endpoint returned a promise, we should wait on it
      #   then(val, conclude, function(error){
      #     # The original error handler would not have run because the endpoint didn't
      #     # synchronously produce any errors. We have to run our error handling logic now.
      #     # TODO: Dry this up with the error handler in route()
      #     v <- private$errorHandler(req, res, error)
      #     conclude(v)
      #   })
      # } else {
      #   conclude(val)
      # }
    },

    route = function(req, res) {
      getHandle <- function(filt) {
        handlers <- private$ends[[filt]]
        if (!is.null(handlers)) {
          for (h in handlers) {
            if (h$canServe(req)) {
              return(h)
            }
          }
        }
        return(NULL)
      }

      # Get args out of the query string, + req/res
      args <- list()
      if (!is.null(req$args)) {
        args <- req$args
      }
      args$res <- res
      args$req <- req

      req$args <- args
      path <- req$PATH_INFO

      makeHandleStep <- function(name) {
        function(...) {
          resetForward()
          h <- getHandle(name)
          if (is.null(h)) {
            return(forward())
          }
          if (!is.null(h$serializer)) {
            res$serializer <- h$serializer
          }
          req$args <- c(h$getPathParams(path), req$args)
          return(do.call(h$exec, req$args))
        }
      }

      steps <- list(
        # first step
        makeHandleStep("__first__")
      )

      # Start running through filters until we find a matching endpoint.
      # returns 2 functions which need to be flattened overall
      filterSteps <- unlist(recursive = FALSE, lapply(private$filts, function(fi) {
        # Check for endpoints preempting in this filter.
        handleStep <- makeHandleStep(fi$name)

        # Execute this filter
        # Do not stop if the filter returned a non-forward object
        # If a non-forward object is returned, serialize it according to the filter
        filterStep <- function(...) {

          filterExecStep <- function(...) {
            resetForward()
            do.call(fi$exec, req$args)
          }
          postFilterStep <- function(fres, ...) {
            if (hasForwarded()) {
              # return like normal
              return(fres)
            }
            # forward() wasn't called, presumably meaning the request was
            # handled inside of this filter.
            if (!is.null(fi$serializer)){
              res$serializer <- fi$serializer
            }
            return(fres)
          }

          runSteps(
            NULL,
            stop,
            list(
              filterExecStep,
              postFilterStep
            )
          )
        }

        list(
          handleStep,
          filterStep
        )
      }))
      steps <- append(steps, filterSteps)

      # If we still haven't found a match, check the un-preempt'd endpoints.
      steps <- append(steps, list(makeHandleStep("__no-preempt__")))

      # We aren't going to serve this endpoint; see if any mounted routers will
      mountSteps <- lapply(names(private$mnts), function(mountPath) {
        # (make step function)
        function(...) {
          resetForward()
          # TODO: support globbing?

          if (nchar(path) >= nchar(mountPath) && substr(path, 0, nchar(mountPath)) == mountPath) {
            # This is a prefix match or exact match. Let this router handle.

            # First trim the prefix off of the PATH_INFO element
            req$PATH_INFO <- substr(req$PATH_INFO, nchar(mountPath), nchar(req$PATH_INFO))
            return(private$mnts[[mountPath]]$route(req, res))
          } else {
            return(forward())
          }
        }
      })
      steps <- append(steps, mountSteps)

      # No endpoint could handle this request. 404
      notFoundStep <- function(...) {
        private$notFoundHandler(req = req, res = res)
      }
      steps <- append(steps, list(notFoundStep))

      errorHandlerStep <- function(error, ...) {
        private$errorHandler(req, res, error)
      }

      withCurrentExecDomain(req, res, { # used to allow `hasForwarded` to work
        withWarn1({
          runStepsIfForwarding(NULL, errorHandlerStep, steps)
        })
      })
    },

    # httpuv interface
    call = function(req) {
      # Set the arguments to an empty list
      req$args <- list()
      req$.internal <- new.env()

      res <- PlumberResponse$new(private$serializer)

      # maybe return a promise object
      self$serve(req, res)
    },
    onHeaders = function(req) {
      NULL
    },
    onWSOpen = function(ws){
      warning("WebSockets not supported.")
    },

    setSerializer = function(serializer){
      private$serializer <- serializer
    }, # Set a default serializer

    set404Handler = function(fun){
      private$notFoundHandler <- fun
    },
    setErrorHandler = function(fun){
      private$errorHandler <- fun
    },

    filter = function(name, expr, serializer){
      filter <- PlumberFilter$new(name, expr, private$envir, serializer)
      private$addFilterInternal(filter)
    },
    swaggerFile = function() { #FIXME: test

      swaggerPaths <- private$swaggerFileWalkMountsInternal(self)

      # Extend the previously parsed settings with the endpoints
      def <- modifyList(private$globalSettings, list(paths = swaggerPaths))

      # Lay those over the default globals so we ensure that the required fields
      # (like API version) are satisfied.
      ret <- modifyList(defaultGlobals, def)

      # remove NA or NULL values, which swagger doesn't like
      ret <- removeNaOrNulls(ret)

      ret
    },
    openAPIFile = function() {
      self$swaggerFile()
    },

    ### Legacy/Deprecated
    addEndpoint = function(verbs, path, expr, serializer, processors, preempt=NULL, params=NULL, comments){
      warning("addEndpoint has been deprecated in v0.4.0 and will be removed in a coming release. Please use `handle()` instead.")
      if (!missing(processors) || !missing(params) || !missing(comments)){
        stop("The processors, params, and comments parameters are no longer supported.")
      }

      self$handle(verbs, path, expr, preempt, serializer)
    },
    addAssets = function(dir, path="/public", options=list()){
      warning("addAssets has been deprecated in v0.4.0 and will be removed in a coming release. Please use `mount` and `PlumberStatic$new()` instead.")
      if (substr(path, 1,1) != "/"){
        path <- paste0("/", path)
      }

      stat <- PlumberStatic$new(dir, options)
      self$mount(path, stat)
    },
    addFilter = function(name, expr, serializer, processors){
      warning("addFilter has been deprecated in v0.4.0 and will be removed in a coming release. Please use `filter` instead.")
      if (!missing(processors)){
        stop("The processors parameter is no longer supported.")
      }

      filter <- PlumberFilter$new(name, expr, private$envir, serializer)
      private$addFilterInternal(filter)
    },
    addGlobalProcessor = function(proc){
      warning("addGlobalProcessor has been deprecated in v0.4.0 and will be removed in a coming release. Please use `registerHook`(s) instead.")
      self$registerHooks(proc)
    }
  ), active = list(
    endpoints = function(){ # read-only
      private$ends
    },
    filters = function(){ # read-only
      private$filts
    },
    mounts = function(){ # read-only
      private$mnts
    },
    environment = function() { #read-only
      private$envir
    },
    routes = function(){
      paths <- list()

      addPath <- function(node, children, endpoint){
        if (length(children) == 0){
          if (is.null(node)){
            return(endpoint)
          } else {
            # Concat to existing.
            return(c(node, endpoint))
          }

        }
        if (is.null(node)){
          node <- list()
        }
        node[[children[1]]] <- addPath(node[[children[1]]], children[-1], endpoint)
        node
      }

      lapply(self$endpoints, function(ends){
        lapply(ends, function(e){
          # Trim leading slash
          path <- sub("^/", "", e$path)

          levels <- strsplit(path, "/", fixed=TRUE)[[1]]
          paths <<- addPath(paths, levels, e)
        })
      })

      # Sub-routers
      if (length(self$mounts) > 0){
        for(i in 1:length(self$mounts)){
          # Trim leading slash
          path <- sub("^/", "", names(self$mounts)[i])

          levels <- strsplit(path, "/", fixed=TRUE)[[1]]

          m <- self$mounts[[i]]
          paths <- addPath(paths, levels, m)
        }
      }

      # TODO: Sort lexicographically

      paths
    }
  ), private = list(
    serializer = NULL, # The default serializer for the router

    ends = list(), # List of endpoints indexed by their pre-empted filter.
    filts = NULL, # Array of filters
    mnts = list(),

    envir = NULL, # The environment in which all API execution will be conducted
    lines = NULL, # The lines constituting the API
    parsed = NULL, # The parsed representation of the API
    globalSettings = list(info=list()), # Global settings for this API. Primarily used for Swagger docs.

    errorHandler = NULL,
    setErrorHandlerInternal = function(errorhandler){
      private$errorHandler <- errorhandler
      invisible(self)
    },
    notFoundHandler = NULL,

    addFilterInternal = function(filter){
      # Create a new filter and add it to the router
      private$filts <- c(private$filts, filter)
      invisible(self)
    },
    addEndpointInternal = function(ep, preempt){
      noPreempt <- missing(preempt) || is.null(preempt)

      filterNames <- "__first__"
      for (f in private$filts){
        filterNames <- c(filterNames, f$name)
      }
      if (!noPreempt && ! preempt %in% filterNames){
        if (!is.null(ep$lines)){
          stopOnLine(ep$lines[1], private$fileLines[ep$lines[1]], paste0("The given @preempt filter does not exist in this plumber router: '", preempt, "'"))
        } else {
          stop(paste0("The given preempt filter does not exist in this plumber router: '", preempt, "'"))
        }
      }

      if (noPreempt){
        preempt <- "__no-preempt__"
      }

      private$ends[[preempt]] <- c(private$ends[[preempt]], ep)
    },

    swaggerFileWalkMountsInternal = function(router, parentPath = "") {
      remove_trailing_slash <- function(x) {
        sub("[/]$", "", x)
      }
      remove_leading_slash <- function(x) {
        sub("^[/]", "", x)
      }
      join_paths <- function(x, y) {
        x <- remove_trailing_slash(x)
        y <- remove_leading_slash(y)
        paste(x, y, sep = "/")
      }

      # make sure to use the full path
      endpointList <- list()

      for (endpoint in router$endpoints) {
        for (endpointEntry in endpoint) {
          swaggerEndpoint <- prepareSwaggerEndpoint(
            endpointEntry,
            join_paths(parentPath, endpointEntry$path)
          )
          endpointList <- modifyList(endpointList, swaggerEndpoint)
        }
      }

      # recursively gather mounted enpoint entries
      if (length(router$mounts) > 0) {
        for (mountPath in names(router$mounts)) {
          mountEndpoints <- private$swaggerFileWalkMountsInternal(
            router$mounts[[mountPath]],
            join_paths(parentPath, mountPath)
          )
          endpointList <- modifyList(endpointList, mountEndpoints)
        }
      }

      # returning a single list of swagger entries
      endpointList
    }
  )
)








urlHost <- function(host, port, changeHostLocation = FALSE) {
  if (isTRUE(changeHostLocation)) {
    # upgrade swaggerCallback location to be localhost and not catch-all addresses
    # shiny: https://github.com/rstudio/shiny/blob/95173f6/R/server.R#L781-L786
    if (identical(host, "0.0.0.0")) {
      # RStudio IDE does NOT like 0.0.0.0 locations.
      # Must use 127.0.0.1 instead.
      host <- "127.0.0.1"
    } else if (identical(host, "::")) {
      # upgrade ipv6 catch-all to ipv6 "localhost"
      host <- "::1"
    }
  }

  # if ipv6 address, surround in brackets
  if (grepl(":[^/]", host)) {
    host <- paste0("[", host, "]")
  }
  # if no match against a protocol
  if (!grepl("://", host)) {
    # add http protocol
    # RStudio IDE does NOT like empty protocols like "127.0.0.1:1234/route"
    # Works if supplying "http://127.0.0.1:1234/route"
    host <- paste0("http://", host)
  }

  paste0(host, ":", port)
}
