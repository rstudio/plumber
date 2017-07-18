#' @import R6
#' @import stringi
NULL

# used to identify annotation flags.
verbs <- c("GET", "PUT", "POST", "DELETE", "HEAD")
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
    file <- file.path(dir, "plumber.R")

  } else {
    # File was specified
    dirMode <- FALSE
  }

  if (dirMode && file.exists(file.path(dir, "entrypoint.R"))){
    # Dir was specified and we found an entrypoint.R

    old <- setwd(dir)
    on.exit(setwd(old))

    # Expect that entrypoint will provide us with the router
    x <- source("entrypoint.R")

    # source returns a list with value and visible elements, we want the (visible) value object.
    pr <- x$value
    if (!("plumber" %in% class(pr))){
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
    runHooks = function(stage, args){
      if (missing(args)){
        args <- list()
      }
      value <- args$value
      for (h in private$hooks[[stage]]){
        ar <- getRelevantArgs(args, plumberExpression=h)

        value <- do.call(h, ar) #TODO: envir=private$envir?

        if ("value" %in% names(ar)){
          # Special case, retain the returned value from the hook
          # and pass it in as the value for the next handler.
          # Ultimately, return value from this function
          args$value <- value
        }
      }
      value
    }
  )
)


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
#' @import crayon
plumber <- R6Class(
  "plumber",
  inherit = hookable,
  public = list(
    initialize = function(file=NULL, filters=defaultPlumberFilters, envir){

      if (!is.null(file) && !file.exists(file)){
        stop("File does not exist: ", file)
      }

      if (missing(envir)){
        private$envir <- new.env(parent=.GlobalEnv)
      } else {
        private$envir <- envir
      }

      if (is.null(filters)){
        filters <- list()
      }

      # Add in the initial filters
      for (fn in names(filters)){
        fil <- PlumberFilter$new(fn, filters[[fn]], private$envir, private$serializer, NULL)
        private$filts <- c(private$filts, fil)
      }

      private$errorHandler <- defaultErrorHandler()
      private$notFoundHandler <- default404Handler

      if (!is.null(file)){
        private$lines <- readLines(file)
        private$parsed <- parse(file, keep.source=TRUE)

        source(file, local=private$envir, echo=FALSE, keep.source=TRUE)

        for (i in 1:length(private$parsed)){
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]][c(1,3)]

          activateBlock(srcref, private$lines, e, private$envir, private$addEndpointInternal,
                        private$addFilterInternal, self$mount)
        }

        private$globalSettings <- parseGlobals(private$fileLines)
      }

    },
    run = function(host='127.0.0.1', port=8000, swagger=interactive(),
                   debug=interactive()){
      message("Starting server to listen on port ", port)

      private$errorHandler <- defaultErrorHandler(debug)

      # Set and restore the wd to make it appear that the proc is running local to the file's definition.
      if (!is.null(private$filename)){
        cwd <- getwd()
        on.exit({ setwd(cwd) })
        setwd(dirname(private$filename))
      }

      if (swagger){
        sf <- self$swaggerFile()
        # Create a function that's hardcoded to return the swaggerfile -- regardless of env.
        fun <- function(){}
        body(fun) <- sf
        self$handle("GET", "/swagger.json", fun, serializer=serializer_unboxed_json())

        plumberFileServer <- PlumberStatic$new(system.file("swagger-ui", package = "plumber"))
        self$mount("/__swagger__", plumberFileServer)
        message("Running the swagger UI at http://127.0.0.1:", port, "/__swagger__/")
      }

      httpuv::runServer(host, port, self)
    },
    mount = function(path, router){
      path <- sub("([^/])$", "\\1/", path)

      private$mnts[[path]] <- router
    },
    registerHook = function(stage=c("preroute", "postroute",
                                    "preserialize", "postserialize"), handler){
      stage <- match.arg(stage)
      super$registerHook(stage, handler)
    },

    handle = function(methods, path, handler, preempt, serializer){
      if (missing(serializer)){
        serializer <- private$serializer
      }

      ep <- PlumberEndpoint$new(methods, path, handler, private$envir, serializer)
      private$addEndpointInternal(ep, preempt)
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
        } else if ("plumber" %in% class(node)){
          cat(prefix, "\u251c\u2500\u2500/", name, "\n", sep="") # "+--"
          # It's a router, let it print itself
          print(node, prefix=childPref, topLevel=FALSE)
        } else if ("PlumberEndpoint" %in% class(node)){
          printEndpoints(prefix, name, node, isLast)
        } else {
          cat("??")
        }
      }
      printNode(paths, "", prefix, TRUE)

      invisible(self)
    },

    serve = function(req, res){
      hookEnv <- new.env()

      private$runHooks("preroute", list(data=hookEnv, req=req, res=res))

      val <- self$route(req, res)

      private$runHooks("postroute", list(data=hookEnv, req=req, res=res, value=val))

      if ("PlumberResponse" %in% class(val)){
        # They returned the response directly, don't serialize.
        res$toResponse()
      } else {
        ser <- res$serializer

        if (typeof(ser) != "closure") {
          stop("Serializers must be closures: '", ser, "'")
        }

        private$runHooks("preserialize", list(data=hookEnv, req=req, res=res, value=val))
        out <- ser(val, req, res, private$errorHandler)
        private$runHooks("postserialize", list(data=hookEnv, req=req, res=res, value=val))
        out
      }
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

        # We aren't going to serve this endpoint; see if any mounted routers will
        for (mountPath in names(private$mnts)){
          # TODO: support globbing?

          if (nchar(path) >= nchar(mountPath) && substr(path, 0, nchar(mountPath)) == mountPath){
            # This is a prefix match or exact match. Let this router handle.

            # First trim the prefix off of the PATH_INFO element
            req$PATH_INFO <- substr(req$PATH_INFO, nchar(mountPath), nchar(req$PATH_INFO))
            return(private$mnts[[mountPath]]$route(req, res))
          }
        }

        # No endpoint could handle this request. 404
        val <- private$notFoundHandler(req=req, res=res)
        return(val)
      }, error=function(e){
        # Error when routing
        val <- private$errorHandler(req, res, e)
        return(val)
      }, finally= options(warn=oldWarn) )
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

    setSerializer = function(serlializer){
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
    swaggerFile = function(){ #FIXME: test
      endpoints <- prepareSwaggerEndpoints(self$endpoints)

      # Extend the previously parsed settings with the endpoints
      def <- modifyList(private$globalSettings, list(paths=endpoints))

      # Lay those over the default globals so we ensure that the required fields
      # (like API version) are satisfied.
      modifyList(defaultGlobals, def)
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
    serializer = serializer_json(), # The default serializer for the router

    ends = list(), # List of endpoints indexed by their pre-empted filter.
    filts = NULL, # Array of filters
    mnts = list(),

    envir = NULL, # The environment in which all API execution will be conducted
    lines = NULL, # The lines constituting the API
    parsed = NULL, # The parsed representation of the API
    globalSettings = list(info=list()), # Global settings for this API. Primarily used for Swagger docs.

    errorHandler = NULL,
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
    }
  )
)

