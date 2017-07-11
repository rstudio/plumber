
# TODO: static asset router that can be mounted onto another router.

#' @include query-string.R
#' @include post-body.R
#' #' @include cookie-parser.R
defaultPlumberFilters <- list(
  queryString = queryStringFilter,
  postBody = postBodyFilter,
  cookieParser = cookieFilter)

#' Plumber Router
#'
#' Routers are the core request handler in plumber. A router is responsible for
#' taking an incoming request, submitting it through the appropriate filters and
#' eventually to a corresponding endpoint, if one is found.
#'
#' See \url{http://plumber.trestletech.com/docs/programmatic/} for additional
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
plumber <- R6Class(
  "plumber",
  public = list(
    initialize = function(file=NULL, filters=defaultPlumberFilters){

      # TODO: is this safe for sub-routers? Would be nice if all routers shared an env by default, no?
      private$envir <- new.env(parent=.GlobalEnv)

      # Add in the initial filters
      for (fn in names(filters)){
        fil <- PlumberFilter$new(fn, filters[[fn]], private$envir, private$serializer, NULL, NULL)
        private$filts <- c(private$filts, fil)
      }

      if (!is.null(file)){
        private$lines <- readLines(file)
        private$parsed <- parse(file, keep.source=TRUE)

        source(file, local=private$envir, echo=FALSE, keep.source=TRUE)

        for (i in 1:length(private$parsed)){
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]][c(1,3)]

          # FIXME: adjust signature here
          activateBlock(srcref, private$lines, e, private$envir, private$addEndpointInternal,
                        private$addFilterInternal, private$addAssetsInternal)
        }

        private$globalSettings <- parseGlobals(private$fileLines)
      }

    },
    run = function(host='127.0.0.1', port=8000, swagger=interactive()){
      message("Starting server to listen on port ", port)

      # Set and restore the wd to make it appear that the proc is running local to the file's definition.
      if (!is.null(private$filename)){
        cwd <- getwd()
        on.exit({ setwd(cwd) })
        setwd(dirname(private$filename))
      }

      httpuv::runServer(host, port, self)
    },
    filter = function(){},
    mount = function(){},

    delete = function(path, handler){ self$handle("DELETE", path, handler) },
    get = function(path, handler){ self$handle("GET", path, handler) },
    head = function(path, handler){ self$handle("HEAD", path, handler) },
    options = function(path, handler){ self$handle("OPTIONS", path, handler) },
    patch = function(path, handler){ self$handle("PATCH", path, handler) },
    post = function(path, handler){ self$handle("POST", path, handler) },
    put = function(path, handler){ self$handle("PUT", path, handler) },

    handle = function(methods, path, handler, preempt, serializer){
      if (missing(serializer)){
        serializer <- private$serializer
      }

      ep <- PlumberEndpoint$new(methods, path, handler, private$envir, serializer)
      private$addEndpointInternal(ep, preempt)
    },
    print = function(...){
      endCount <- sum(sapply(r$endpoints, length))
      cat("# Plumber router with", endCount, "endpoints and",
          length(private$filts), "filters.\n")
      cat("# Call run() on this object to start the API.\n")
      invisible(self)
    },

    # FIXME: private?
    serve = function(req, res){
      # FIXME: instead of global processors, could we use hooks that allow you to register custom
      # logic for "pre-route", "pre-serialize", "post-serialize", etc?

      val <- private$route(req, res)

      if ("PlumberResponse" %in% class(val)){
        # They returned the response directly, don't serialize.
        res$toResponse()
      } else {
        ser <- res$serializer

        if (typeof(ser) != "closure") {
          stop("Serializers must be closures: '", ser, "'")
        }

        ser(val, req, res, private$errorHandler)
      }
    },

    # httpuv interface
    call = function(req){
      # Due to https://github.com/rstudio/httpuv/issues/49, we need to close
      # the TCP channels via `Connection: close` header. Otherwise we would
      # reuse the same environment for each request and potentially recycle
      # old data here.
      # Set the arguments to an empty list
      req$args <- list()

      res <- PlumberResponse$new(private$serializer)
      self$serve(req, res)
    },
    onHeaders = function(req){
      NULL
    },
    onWSOpen = function(ws){
      warning("WebSockets not supported.")
    },

    # Legacy
    setSerializer = function(name){}, # Set a default serializer
    addGlobalProcessor = function(proc){}, #FIXME
    set404Handler = function(fun){},
    setErrorHandler = function(fun){},
    addAssets = function(dir, path="/public", options=list()){},
    addEndpoint = function(verbs, path, expr, serializer, processors, preempt=NULL, params=NULL, comments){},
    addFilter = function(name, expr, serializer, processors){},
    swaggerFile = function(){}

  ), active = list(
    mountpath = function(){ # read-only

    },
    endpoints = function(){ # read-only
      # TODO
      private$ends
    },
    filters = function(){ # read-only

    },
    mounts = function(){ # read-only

    }
  ), private = list(
    serializer = jsonSerializer(), # The default serializer
    ends = list(), # List of endpoints indexed by their pre-empted filter.
    filts = NULL, # Array of filters
    envir = NULL, # The environment in which all API execution will be conducted
    lines = NULL, # The lines constituting the API
    parsed = NULL, # The parsed representation of the API
    globalSettings = list(info=list()), # Global settings for this API. Primarily used for Swagger docs.

    errorHandler = defaultErrorHandler,
    notFoundHandler = default404Handler,

    addEndpointInternal = function(ep, preempt){
      noPreempt <- missing(preempt) || is.null(preempt)

      # PlumberEndpoint$new(verbs, path, expr, private$envir, serializer, processors, srcref, params, comments, responses)
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
    route = function(req, res){
      getHandle <- function(filt){
        handlers <- private$ends[[filt]]
        if (!is.null(handlers)){
          for (h in handlers){
            if (h$canServe(req)){
              return(h)
            }
          }
        }
        NULL
      }

      # Get args out of the query string, + req/res
      args <- list()
      if (!is.null(req$args)){
        args <- req$args
      }
      args$res <- res
      args$req <- req

      req$args <- args
      path <- req$PATH_INFO

      oldWarn <- options("warn")[[1]]
      tryCatch({
        # Set to show warnings immediately as they happen.
        options(warn=1)

        h <- getHandle("__first__")
        if (!is.null(h)){
          if (!is.null(h$serializer)){
            res$serializer <- h$serializer
          }
          req$args <- c(h$getPathParams(path), req$args)
          return(do.call(h$exec, req$args))
        }

        if (length(private$filts) > 0){
          # Start running through filters until we find a matching endpoint.
          for (i in 1:length(private$filts)){
            fi <- private$filts[[i]]

            # Check for endpoints preempting in this filter.
            h <- getHandle(fi$name)
            if (!is.null(h)){
              if (!is.null(h$serializer)){
                res$serializer <- h$serializer
              }
              req$args <- c(h$getPathParams(path), req$args)
              return(do.call(h$exec, req$args))
            }

            # Execute this filter
            .globals$forwarded <- FALSE
            fres <- do.call(fi$exec, req$args)
            if (!.globals$forwarded){
              # forward() wasn't called, presumably meaning the request was
              # handled inside of this filter.
              if (!is.null(fi$serializer)){
                res$serializer <- fi$serializer
              }
              return(fres)
            }
          }
        }

        # If we still haven't found a match, check the un-preempt'd endpoints.
        h <- getHandle("__no-preempt__")
        if (!is.null(h)){
          if (!is.null(h$serializer)){
            res$serializer <- h$serializer
          }
          req$args <- c(h$getPathParams(path), req$args)
          return(do.call(h$exec, req$args))
        }

        # No endpoint could handle this request. 404
        val <- private$notFoundHandler(req=req, res=res)
        return(val)
      }, error=function(e){
        # Error when filtering
        val <- private$errorHandler(req, res, e)
        return(val)
      }, finally= options(warn=oldWarn) )
    }
  )
)

