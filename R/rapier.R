#' @import R6
#' @import stringi
NULL

.globals <- new.env()
.globals$serializers <- list()

verbs <- c("GET", "PUT", "POST", "DELETE")
enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(verbs)
  }
  toupper(v)
}

#' @export
RapierRouter <- R6Class(
  "RapierRouter",
  public = list(
    endpoints = list(),
    filters = NULL,
    debug = TRUE,
    initialize = function(file) {
      if (!file.exists(file)){
        stop("File does not exist: ", file)
      }

      private$errorHandler <- defaultErrorHandler
      private$notFoundHandler <- default404Handler

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
        png <- FALSE
        jpeg <- FALSE
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

          pngMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@png(\\s+(.*)\\s*$)?")
          if (!is.na(pngMat[1,1])){
            if (png){
              # Must have already assigned.
              stopOnLine(line, "Multiple @png annotations on one function.")
            }
            png <- TRUE
          }

          jpegMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@jpeg(\\s+(.*)\\s*$)?")
          if (!is.na(jpegMat[1,1])){
            if (jpeg){
              # Must have already assigned.
              stopOnLine(line, "Multiple @jpeg annotations on one function.")
            }
            jpeg <- TRUE
          }

          line <- line - 1
        }

        if ((jpeg || png) && !is.null(serializer)){
          warning("A @serializer definition on a @png/@jpeg function is meaningless and will be ignored.")
          if (png){
            serializer <- "png"
          } else if (jpeg){
            serializer <- "jpeg"
          }
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
      res <- RapierResponse$new()
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
    setSerializer = function(name){
      private$defaultSerializer <- name
    },
    serve = function(req, res){
      ret <- self$route(req, res)
      val <- ret$value
      ser <- ret$serializer

      if (is.null(ser) || ser == ""){
        ser <- .globals$serializers[[private$defaultSerializer]]
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
        # Get args out of the query string, + req/res
        args <- queryStringParser(req, res)
        args <- c(args, postBodyParser(req, res))
        args[["res"]] <- res
        args[["req"]] <- req

        h <- getHandle("__first__")
        if (!is.null(h)){
          return(list(serializer = h$serializer, value = do.call(h$exec, args)))
        }

        if (length(self$filters) > 0){
          # Start running through filters until we find a matching endpoint.
          for (i in 1:length(self$filters)){
            fi <- self$filters[[i]]

            # Check for endpoints preempting in this filter.
            h <- getHandle(fi$name)
            if (!is.null(h)){
              return(list(serializer = h$serializer, value = do.call(h$exec, args)))
            }

            # Execute this filter
            .globals$forwarded <- FALSE
            fres <- do.call(fi$exec, args)
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
          return(list(serializer = h$serializer, value = do.call(h$exec, args)))
        }

        # No endpoint could handle this request. 404
        private$notFoundHandler(req=req, res=res)
        return(list(serializer="null", value = res$body))
      }, error=function(e){
        # Error when filtering
        private$errorHandler(req, res, e)
        return(list(serializer="null", value = res$body))
      })
    },
    run = function(host='0.0.0.0', port=8000){
      .globals$debug <- self$debug
      message("Starting server to listen on port ", port)
      httpuv::runServer(host, port, self)
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
    defaultSerializer = "json"
  )
)

#' Create a new rapier router.
#' @export
rapier <- function(file){
  RapierRouter$new(file)
}
