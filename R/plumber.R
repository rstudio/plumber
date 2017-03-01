#' @import R6
#' @import stringi
#' @import feather
#' @import webutils
NULL

verbs <- c("GET", "PUT", "POST", "DELETE", "HEAD")
enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(verbs)
  }
  toupper(v)
}


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
#'   plumber router definition
#' @include globals.R
#' @include serializer-json.R
#' @include parse-block.R
#' @include parse-globals.R
#' @export
#' @importFrom httpuv runServer
plumber <- R6Class(
  "plumber",
  public = list(
    endpoints = list(),
    filters = NULL,
    debug = TRUE,
    initialize = function(file=NULL) {
      if (!is.null(file) && !file.exists(file)){
        stop("File does not exist: ", file)
      }

      private$errorHandler <- defaultErrorHandler
      private$notFoundHandler <- default404Handler

      self$filters <- c(self$filters, PlumberFilter$new("queryString",
          queryStringFilter, private$envir, private$defaultSerializer, NULL, NULL))
      self$filters <- c(self$filters, PlumberFilter$new("postBody",
          postBodyFilter, private$envir, private$defaultSerializer, NULL, NULL))
      self$filters <- c(self$filters, PlumberFilter$new("cookieParser",
          cookieFilter, private$envir, private$defaultSerializer, NULL, NULL))

      private$filename <- file
      private$envir <- new.env(parent=.GlobalEnv)

      if (!is.null(file)){
        private$fileLines <- readLines(file)
        private$parsed <- parse(file, keep.source=TRUE)

        source(file, local=private$envir, echo=FALSE, keep.source=TRUE)

        for (i in 1:length(private$parsed)){
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]][c(1,3)]

          activateBlock(srcref, private$fileLines, e, private$addEndpointInternal,
                        private$addFilterInternal, private$addAssetsInternal)
        }

        private$globalSettings <- parseGlobals(private$fileLines)
      }

      # TODO check for colliding filter names and endpoint addresses.
    },
    call = function(req){ #httpuv interface
      # Due to https://github.com/rstudio/httpuv/issues/49, we need to close
      # the TCP channels via `Connection: close` header. Otherwise we would
      # reuse the same environment for each request and potentially recycle
      # old data here.

      # Set the arguments to an empty list
      req$args <- list()

      res <- PlumberResponse$new(private$defaultSerializer)
      self$serve(req, res)
    },
    onHeaders = function(req){ #httpuv interface
      NULL
    },
    onWSOpen = function(ws){ #httpuv interface
      warning("WebSockets not supported")
    },
    #* @param verbs The verb(s) which this endpoint supports
    #* @param path The path for the endpoint
    #* @param expr The expression encapsulating the endpoint's logic
    #* @param serializer The name of the serializer to use (if not the default)
    #* @param processors Any \code{PlumberProcessors} to apply to this endpoint
    #* @param preempt The name of the filter before which this endpoint should
    #*   be inserted. If not specified the endpoint will be added after all
    #*   the filters.
    #* @param params The documented parameters for this function in a list of
    #*   list(paramsName=list(desc="description here") lists.
    #* @param comments A description of the endpoint
    addEndpoint = function(verbs, path, expr, serializer, processors, preempt=NULL, params=NULL, comments){
      private$addEndpointInternal(verbs, path, expr, serializer, processors, srcref, preempt, params, comments)
    },
    #* Adds a static asset server
    #*
    #* @param dir The directory on disk from which to serve static assets
    #* @param path The path prefix at which the assets should be made available
    #* @param options A list of configuration options. Currently none are
    #*   supported
    addAssets = function(dir, path="/public", options=list()){
      private$addAssetsInternal(dir, path, options)
    },
    setErrorHandler = function(fun){
      private$errorHandler <- fun
      invisible(self)
    },
    set404Handler = function(fun){
      private$notFoundHandler = fun
    },
    #* @param name The name of the filter
    #* @param expr The expression encapsulating the filter's logic
    #* @param serializer (optional) A custom serializer to use when writing out
    #*   data from this filter.
    #* @param processors The \code{\link{PlumberProcessor}}s to apply to this
    #*   filter.
    addFilter = function(name, expr, serializer, processors){
      "Create a new filter and add it to the router"
      private$addFilterInternal(name, expr, serializer, processors)
    },
    setSerializer = function(name){
      private$defaultSerializer <- name
    },
    addGlobalProcessor = function(proc){
      private$globalProcessors <- c(private$globalProcessors, proc)
    },
    serve = function(req, res){
      # Apply pre-routing logic
      for ( p in private$globalProcessors ) {
        p$pre(req=req, res=res)
      }

      val <- self$route(req, res)

      # Apply post-routing logic
      for ( p in private$globalProcessors ) {
        val <- p$post(value=val, req=req, res=res)
      }

      if ("PlumberResponse" %in% class(val)){
        # They returned the response directly, don't serialize.
        res$toResponse()
      } else {
        ser <- res$serializer

        if (is.null(ser)){
          ser <- .globals$serializers[[private$defaultSerializer]]()
        } else if (typeof(ser) != "closure") {
          stop("Serializers must be closures: '", ser, "'")
        }

        ser(val, req, res, private$errorHandler)
      }
    },
    route = function(req, res){
      getHandle <- function(filt){
        handlers <- self$endpoints[[filt]]
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

        if (length(self$filters) > 0){
          # Start running through filters until we find a matching endpoint.
          for (i in 1:length(self$filters)){
            fi <- self$filters[[i]]

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
    },
    run = function(host='0.0.0.0', port=8000, swagger=interactive()){
      # TODO: setwd to file path
      .globals$debug <- self$debug
      message("Starting server to listen on port ", port)

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
        self$addEndpoint("GET", "/swagger.json", fun, unboxedJsonSerializer())
        self$addAssets(system.file("swagger-ui", package = "plumber"), path="/__swagger__")
        message("Running the swagger UI at http://127.0.0.1:", port, "/__swagger__/")
      }

      httpuv::runServer(host, port, self)
    },
    swaggerFile = function(){
      endpoints <- prepareSwaggerEndpoints(self$endpoints)

      # Extend the previously parsed settings with the endpoints
      def <- modifyList(private$globalSettings, list(paths=endpoints))
      # Lay those over the default globals so we ensure that the required fields
      # (like API version) are satisfied.
      modifyList(defaultGlobals, def)
    }
    #TODO: addRouter() to add sub-routers at a path.
  ),
  private = list(
    errorHandler = NULL,
    notFoundHandler = NULL,
    filename = NA,
    fileLines = NA,
    parsed = NA,
    envir = NULL,
    globalSettings = list(info=list()),
    defaultSerializer = jsonSerializer(),
    globalProcessors = NULL,
    addFilterInternal = function(name, expr, serializer, processors, lines){
      "Create a new filter and add it to the router"
      filter <- PlumberFilter$new(name, expr, private$envir, serializer, processors, lines)
      self$filters <- c(self$filters, filter)
      invisible(self)
    },
    addEndpointInternal = function(verbs, path, expr, serializer, processors, srcref, preempt=NULL, params=NULL, comments=NULL, responses=NULL){
      filterNames <- "__first__"
      for (f in self$filters){
        filterNames <- c(filterNames, f$name)
      }

      if (!is.null(preempt) && !preempt %in% filterNames){
        if (!is.null(srcref)){
          stopOnLine(srcref[1], private$fileLines[srcref[1]], paste0("The given @preempt filter does not exist in this plumber router: '", preempt, "'"))
        } else {
          stop(paste0("The given preempt filter does not exist in this plumber router: '", preempt, "'"))
        }
      }

      preempt <- ifelse(is.null(preempt), "__no-preempt__", preempt)
      self$endpoints[[preempt]] <- c(self$endpoints[[preempt]], PlumberEndpoint$new(verbs, path, expr, private$envir, preempt, serializer, processors, srcref, params, comments, responses))
    },
    addAssetsInternal = function(direc, pathPrefix="/public", options=list(), srcref){
      if(missing(direc)){
        stop("Cannot add asset directory when no directory was specified")
      }

      if(substr(direc, 1, 2) == "./"){
        direc <- substr(direc, 3, nchar(direc))
      }

      if (substr(pathPrefix, 1,1) != "/"){
        pathPrefix <- paste0("/", pathPrefix)
      }

      # Evaluate to convert to list
      if (is.function(options)){
        options <- options()
      } else if (is.expression(options)){
        options <- eval(options, private$envir)
      }

      expr <- function(req, res){
        # Adapted from shiny:::staticHandler
        if (!identical(req$REQUEST_METHOD, 'GET')){
          return(forward())
        }

        path <- req$PATH_INFO

        if (is.null(path)){
          res$body <- "<h1>Bad Request</h1>"
          res$status <- 400
        }

        # Trim off the prefix
        if (!stri_startswith_fixed(path, pathPrefix)){
          # Not ours to handle
          return(forward())
        }
        path <- substr(path, nchar(pathPrefix)+1, nchar(path))

        if (path == '/')
          path <- '/index.html'

        abs.path <- resolve(direc, path)
        if (is.null(abs.path)){
          return(forward())
        }

        ext <- tools::file_ext(abs.path)
        contentType <- getContentType(ext)
        responseContent <- readBin(abs.path, 'raw', n=file.info(abs.path)$size)

        res$status <- 200
        res$setHeader("Content-type", contentType)
        res$body <- responseContent
        res
      }
      private$addFilterInternal(paste("static-asset", direc, pathPrefix, sep="|"), expr, "null", NULL, srcref)
    }
  )
)

#' @rdname plumber
#' @export
plumb <- function(file, dir){
  if(!xor(missing(file), missing(dir))){
    stop("plumber needs only one of a file or a directory with a `plumber.R` file in its root.")
  } else if (missing(file)){
    dir <- sub("/$", "", dir)
    file <- file.path(dir,"plumber.R")
  }
  plumber$new(file)
}

