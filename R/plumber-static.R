
#' Static file router
#'
#' Creates a router that is backed by a directory of files on disk.
#' @include plumber.R
#' @export
PlumberStatic <- R6Class(
  "PlumberStatic",
  inherit = Plumber,
  public = list(
    #' @description Create a new `PlumberStatic` router
    #' @param direc a path to an asset directory.
    #' @param options options to be evaluated in the `PlumberStatic` router environment
    #' @return A new `PlumberStatic` router
    initialize = function(direc, options) {
      super$initialize(filters=NULL)

      private$dir <- direc

      if (missing(direc)) {
        stop("Cannot add asset directory when no directory was specified")
      }

      # Relative paths
      if (substr(direc, 1, 2) == "./") {
        direc <- substr(direc, 3, nchar(direc))
      }

      if (missing(options)) {
        options <- list()
      }

      # Evaluate to convert to list
      if (is.function(options)) {
        options <- options()
      } else if (is.expression(options)) {
        options <- eval(options, private$envir)
      }

      badRequest <- function(res) {
        res$body <- "<h1>Bad Request</h1>"
        res$status <- 400
        res
      }

      expr <- function(req, res) {
        # Adapted from shiny:::staticHandler
        if (!req$REQUEST_METHOD %in% c('GET', 'HEAD')) {
          return(badRequest(res))
        }

        path <- req$PATH_INFO

        if (is.null(path)) {
          return(badRequest(res))
        }

        if (path == '/') {
          path <- '/index.html'
        }

        abs.path <- resolve_path(direc, path)
        if (is.null(abs.path)) {
          # TODO: Should this be inherited from a parent router?
          val <- private$notFoundHandler(req=req, res=res)
          return(val)
        }

        ext <- tools::file_ext(abs.path)
        info <- file.info(abs.path)
        contentType <- getContentType(ext)
        res$setHeader("Content-Type", contentType)
        res$setHeader("Content-Length", info$size)
        res$setHeader("Last-Modified", http_date_string(info$mtime))
        res$body <-
          if (req$REQUEST_METHOD == 'GET')
            readBin(abs.path, 'raw', n = info$size)
        res$status <- 200
        res
      }

      filter <- PlumberFilter$new(paste("static-asset", direc, sep="|"), expr, private$envir)
      private$addFilterInternal(filter)
    },
    #' @description Print representation of `PlumberStatic()` router.
    #' @param prefix a character string. Prefix to append to representation.
    #' @param topLevel a logical value. When method executed on top level
    #' router, set to `TRUE`.
    #' @param ... additional arguments for recursive calls
    #' @return A terminal friendly representation of a `PlumberStatic()` router.
    print = function(prefix="", topLevel=TRUE, ...) {
      cat(prefix)
      if (!topLevel) {
        cat("\u2502 ")
      }
      cat(crayon::silver("# Plumber static router serving from directory: ", private$dir, "\n", sep = ""))
    }
  ), private=list(
    dir = NULL
  )
)
