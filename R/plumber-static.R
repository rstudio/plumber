
#' @include plumber.R
#' @noRd
PlumberStatic <- R6Class(
  "PlumberStatic",
  inherit = plumber,
  public = list(
    initialize = function(direc, options){
      super$initialize(filters=NULL)

      private$dir <- direc

      if(missing(direc)){
        stop("Cannot add asset directory when no directory was specified")
      }

      # Relative paths
      if(substr(direc, 1, 2) == "./"){
        direc <- substr(direc, 3, nchar(direc))
      }

      if (missing(options)){
        options <- list()
      }

      # Evaluate to convert to list
      if (is.function(options)){
        options <- options()
      } else if (is.expression(options)){
        options <- eval(options, private$envir)
      }

      badRequest <- function(res){
        res$body <- "<h1>Bad Request</h1>"
        res$status <- 400
        res
      }

      expr <- function(req, res){
        # Adapted from shiny:::staticHandler
        if (!identical(req$REQUEST_METHOD, 'GET')){
          return(badRequest(res))
        }

        path <- req$PATH_INFO

        if (is.null(path)){
          return(badRequest(res))
        }

        if (path == '/'){
          path <- '/index.html'
        }

        abs.path <- resolve(direc, path)
        if (is.null(abs.path)){
          # TODO: Should this be inherited from a parent router?
          val <- private$notFoundHandler(req=req, res=res)
          return(val)
        }

        ext <- tools::file_ext(abs.path)
        contentType <- getContentType(ext)
        responseContent <- readBin(abs.path, 'raw', n=file.info(abs.path)$size)

        res$status <- 200
        res$setHeader("Content-type", contentType)
        res$body <- responseContent
        res
      }

      filter <- PlumberFilter$new(paste("static-asset", direc, sep="|"), expr, private$envir)
      private$addFilterInternal(filter)
    },
    print = function(...){
      cat("# Plumber static router serving from directory:", private$dir)
    }
  ), private=list(
    dir = NULL
  )
)
