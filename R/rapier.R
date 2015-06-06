#' @import R6
#' @import stringi
NULL

jsonSerializer <- function(val, req, res, errorHandler){
  tryCatch({
    json <- jsonlite::toJSON(val)
    return(list(
      status = 200L,
      headers = list( 'Content-Type' = 'application/json'),
      body = json
    ))
  }, error=function(e){
    errorHandler(req, res, e)
  })
}

xmlSerializer <- function(val, req, res, errorHandler){
  if (!requireNamespace("XML", quietly = TRUE)) {
    stop("The XML package is not available but is required in order to use the XML serializer.",
         call. = FALSE)
  }

  stop("XML serialization not yet implemented")
}

.globals <- new.env()
.globals$serializers <- list(
  "json" = jsonSerializer,
  "xml" = xmlSerializer
)

verbs <- toupper(c("get", "put", "post", "delete"))

enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(verbs)
  }
  toupper(v)
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

#' @export
RapierRouter <- R6Class(
  "RapierRouter",
  public = list(
    endpoints = list(),
    filters = NULL,
    initialize = function(file) {
      if (!file.exists(file)){
        stop("File does not exist: ", file)
      }

      private$errorHandler <- function(req, res, err){ print(err); stop ("Error Handler not implemented!") }
      private$notFoundHandler <- function(req, res, err){ stop("404 Not Found Handler not implemented!") }

      stopOnLine <- function(line, msg){
        stop("Error on line #", line, ": '",private$fileLines[line],"' - ", msg)
      }

      private$filename <- file

      private$fileLines <- readLines(file)
      private$parsed <- parse(file, keep.source=TRUE)

      private$envir <- new.env()
      source(file, local=private$envir, echo=FALSE, keep.source=TRUE)

      for (i in 1:length(private$parsed)){
        e <- private$parsed[i]

        srcref <- attr(e, "srcref")[[1]][c(1,3)]

        # Check to see if this function was annotated with a rapier annotation
        line <- srcref[1] - 1

        path <- NULL
        verbs <- NULL
        preempt <- NULL
        filter <- NULL
        serializer <- NULL
        while (line > 0 && (stri_startswith(private$fileLines[line], fixed="#'") || stri_trim_both(private$fileLines[line]) == "")){
          epMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@(get|put|post|use|delete)(\\s+(.*)$)?")
          if (!is.na(epMat[1,2])){
            p <- stri_trim_both(epMat[1,4])

            if (is.na(p) || p == ""){
              stopOnLine(line, "No path specified.")
            }

            verbs <- c(verbs, enumerateVerbs(epMat[1,2]))
            path <- p
          }

          filterMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@filter(\\s+(.*)$)?")
          if (!is.na(filterMat[1,1])){
            f <- stri_trim_both(filterMat[1,3])

            if (is.na(f) || f == ""){
              stopOnLine(line, "No @filter name specified.")
            }

            if (!is.null(filter)){
              # Must have already assigned.
              stopOnLine(line, "Multiple @filters specified for one function.")
            }

            filter <- f
          }

          preemptMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@preempt(\\s+(.*)\\s*$)?")
          if (!is.na(preemptMat[1,1])){
            p <- stri_trim_both(preemptMat[1,3])
            if (is.na(p) || p == ""){
              stopOnLine(line, "No @preempt specified")
            }
            if (!is.null(preempt)){
              # Must have already assigned.
              stopOnLine(line, "Multiple @preempts specified for one function.")
            }
            preempt <- p
          }

          serMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@serializer(\\s+(.*)\\s*$)?")
          if (!is.na(serMat[1,1])){
            s <- stri_trim_both(serMat[1,3])
            if (is.na(s) || s == ""){
              stopOnLine(line, "No @serializer specified")
            }
            if (!is.null(serializer)){
              # Must have already assigned.
              stopOnLine(line, "Multiple @serializers specified for one function.")
            }

            if (!s %in% names(.globals$serializers)){
              stop("No such @serializer registered: ", s)
            }

            serializer <- s
          }

          line <- line - 1
        }

        if (!is.null(filter) && !is.null(path)){
          stopOnLine(line, "A single function can't be both a filter and an API endpoint (@filter AND @get, @post, etc.)")
        }

        if (!is.null(path)){
          preemptName <- ifelse(is.null(preempt), "__no-preempt__", preempt)
          self$endpoints[[preemptName]] <- c(self$endpoints[[preemptName]], RapierEndpoint$new(verbs, path, e, private$envir, preempt, serializer, srcref))
        } else if (!is.null(filter)){
          self$filters <- c(self$filters, RapierFilter$new(filter, e, private$envir, serializer, srcref))
        }
      }

      #TODO: This logic should probably be in addEndpoint which should be leveraged here.
      endpointNames <- "__first__"
      for (f in self$filters){
        endpointNames <- c(endpointNames, f$name)
      }

      for (n in names(self$endpoints)){
        for (e in self$endpoints[[n]]){
          if (!is.na(e$preempt) && !e$preempt %in% endpointNames){
            stopOnLine(e$lines[1], paste0("The given @preempt function does not exist in the rapier environment: '", e$preempt, "'"))
          }
        }
      }

      # TODO check for colliding filter names and endpoint addresses.

    },
    call = function(req){ #httpuv interface
      res <- list()
      self$serve(req, res)
    },
    onHeaders = function(req){ #httpuv interface
      NULL
    },
    onWSOpen = function(ws){ #httpuv interface
      warning("WebSockets not supported")
    },
    addEndpoint = function(verbs, uri, expr, preempt=NULL){
      self$endpoints <- c(self$endpoints, RapierEndpoint$new(verbs, uri, expr, private$envir, preempt))
      invisible(self)
    },
    setErrorHandler = function(fun){
      private$errorHandler <- fun
      invisible(self)
    },
    set404Handler = function(fun){
      private$notFoundHandler = fun
    },
    addFilter = function(filter){
      private$filters <- c(private$filters, filter)
      invisible(self)
    },
    serve = function(req, res){
      ret <- self$route(req, res)
      val <- ret$value
      ser <- ret$serializer

      if (is.null(ser) || ser == ""){
        ser <- jsonSerializer
      } else if (ser %in% names(.globals$serializers)){
        ser <- .globals$serializers[[ser]]
      } else {
        stop("Can't identify serializer '", ser, "'")
      }

      ser(val, req, res, private$errorHandler)
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

      tryCatch({
        h <- getHandle("__first__")
        if (!is.null(h)){
          return(list(serializer = h$serializer, value = h$exec(req=req, res=res)))
        }


        if (length(self$filters) > 0){
          # Start running through filters until we find a matching endpoint.
          for (i in 1:length(self$filters)){
            fi <- self$filters[[i]]

            # Check for endpoints preempting in this filter.
            h <- getHandle(fi$name)
            if (!is.null(h)){
              return(list(serializer = h$serializer, value = h$exec(req=req, res=res)))
            }

            # Execute this filter
            .globals$forwarded <- FALSE
            fres <- fi$exec(req=req, res=res)
            if (!.globals$forwarded){
              # forward() wasn't called, presumably meaning the request was
              # handled inside of this filter.
              return(list(serializer = fi$serializer, value = fres))
            }
          }
        }

        # If we still haven't found a match, check the un-preempt'd endpoints.
        h <- getHandle("__no-preempt__")
        if (!is.null(h)){
          return(list(serializer = h$serializer, value = h$exec(req=req, res=res)))
        }

        # No endpoint could handle this request. 404
        private$notFoundHandler(req=req, res=res)
        return(NULL)
      }, error=function(e){
        # Error when filtering
        private$errorHandler(req, res, e)
        return(NULL)
      })
    }
    #TODO: addRouter() to add sub-routers at a path.
  ),
  private = list(
    errorHandler = NULL,
    notFoundHandler = NULL,
    filename = NA,
    fileLines = NA,
    parsed = NA,
    envir = NULL
  )
)

#' @export
serve <- function(router, host='0.0.0.0', port=8000){
  message("Starting server to listen on port ", 8000)
  tryCatch( httpuv::runServer(host, port, router),
            error=function(e){
              print(str(e))
            }
  )

}

#' @export
forward <- function(){
  .globals$forwarded <- TRUE
}

#' @export
addSerializer <- function(name, serializer){
  if (!is.null(.globals$serializers[[name]])){
    stop ("Already have a serializer by the name of ", name)
  }
  .globals$serializers[[name]] <- serializer
}
