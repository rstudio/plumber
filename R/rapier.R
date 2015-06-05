#' @import R6
#' @import stringi
NULL

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
    initialize = function(expr, envir, lines){
      private$expr <- expr
      private$envir <- envir

      if (!missing(lines)){
        self$lines <- lines
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
    prior = NA,
    verbs = NA,
    path = NA,
    canServe = function(req){
      #TODO: support non-identical paths
      req$REQUEST_METHOD %in% self$verbs && identical(req$PATH_INFO, self$path)
    },
    initialize = function(verbs, path, expr, envir, prior, lines){
      self$verbs <- verbs
      self$path <- path

      private$expr <- expr
      private$envir <- envir

      if (!missing(prior) && !is.null(prior)){
        self$prior <- prior
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
    initialize = function(name, expr, envir, lines){
      self$name <- name
      private$expr <- expr
      private$envir <- envir

      if (!missing(lines)){
        self$lines <- lines
      }
    }
  )
)

RapierRouter <- R6Class(
  "RapierRouter",
  public = list(
    endpoints = list(),
    filters = NULL,
    initialize = function(file) {
      if (!file.exists(file)){
        stop("File does not exist: ", file)
      }

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
        prior <- NULL
        filter <- NULL
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

          priorMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@prior(\\s+(.*)\\s*$)?")
          if (!is.na(priorMat[1,1])){
            p <- stri_trim_both(priorMat[1,3])
            if (is.na(p) || p == ""){
              stopOnLine(line, "No @prior specified")
            }
            if (!is.null(prior)){
              # Must have already assigned.
              stopOnLine(line, "Multiple @priors specified for one function.")
            }
            prior <- p
          }

          line <- line - 1
        }

        if (!is.null(filter) && !is.null(path)){
          stopOnLine(line, "A single function can't be both a filter and an API endpoint (@filter AND @get, @post, etc.)")
        }

        if (!is.null(path)){
          priorName <- ifelse(is.null(prior), "__no-prior__", prior)
          self$endpoints[[priorName]] <- c(self$endpoints[[priorName]], RapierEndpoint$new(verbs, path, e, private$envir, prior, srcref))
        } else if (!is.null(filter)){
          self$filters <- c(self$filters, RapierFilter$new(filter, e, private$envir, srcref))
        }
      }

      #TODO: This logic should probably be in addEndpoint which should be leveraged here.
      endpointNames <- "__first__"
      for (f in self$filters){
        endpointNames <- c(endpointNames, f$name)
      }

      for (n in names(self$endpoints)){
        for (e in self$endpoints[[n]]){
          if (!is.na(e$prior) && !e$prior %in% endpointNames){
            stopOnLine(e$lines[1], paste0("The given @prior function does not exist in the rapier environment: '", e$prior, "'"))
          }
        }
      }
      # TODO check for colliding filter names and endpoint addresses.

    },
    addEndpoint = function(verbs, uri, expr, prior=NULL){
      self$endpoints <- c(self$endpoints, RapierEndpoint$new(verbs, uri, expr, private$envir, prior))
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
          return(h$exec(req=req, res=res))
        }

        # Start running through filters until we find a matching endpoint.
        for (i in 1:length(self$filters)){
          fi <- self$filters[[i]]

          fi$exec(req=req, res=res)
          # Check for endpoints rooted in this filter.
          h <- getHandle(fi$name)
          if (!is.null(h)){
            return(h$exec(req=req, res=res))
          }
        }

        # If we still haven't found a match, check the un-prior'd endpoints.
        h <- getHandle("__no-prior__")
        if (!is.null(h)){
          return(h$exec(req=req, res=res))
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
    errorHandler = NA,
    notFoundHandler = NA,
    filename = NA,
    fileLines = NA,
    parsed = NA,
    envir = NULL
  )
)

#' Generate a Rapier API
#'
#' @export
rapier <- function(){

}
