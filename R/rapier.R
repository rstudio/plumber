#' @import R6
#' @import stringi
NULL

enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(c("get", "put", "post", "delete"))
  }
  v
}

RapierEndpoint <- R6Class(
  "RapierEndpoint",
  public = list(
    verbs = NA,
    uri = NA,
    prior = NA,
    initialize = function(verbs, uri, expr, envir, prior, lines){
      self$verbs <- verbs
      self$uri <- uri

      private$expr <- expr
      private$envir <- envir

      if (!missing(prior) && !is.null(prior)){
        self$prior <- prior
      }
      if (!missing(lines)){
        private$lines <- lines
      }
    }
  ),
  active = list(
    exec = function(){
      eval(private$expr, envir=private$envir)
    }
  ),
  private = list(
    envir = NA,
    expr = NA,
    lines = NA
  )
)

RapierSource <- R6Class(
  "RapierSource",
  public = list(
    endpoints = NULL,
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

        endpoint <- NULL
        verbs <- NULL
        prior <- NULL
        while (line > 0 && (stri_startswith(private$fileLines[line], fixed="#'") || stri_trim_both(private$fileLines[line]) == "")){
          epMat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*@(get|put|post|use|delete)(\\s+(.*)$)?")
          if (!is.na(epMat[1,2])){
            # A rapier annotation, add it.

            p <- stri_trim_both(epMat[1,4])

            if (is.na(p) || p == ""){
              stopOnLine(line, "No path specified.")
            }

            verbs <- c(verbs, enumerateVerbs(epMat[1,2]))
            endpoint <- p
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

        if (!is.null(endpoint)){
          self$endpoints <- c(self$endpoints, RapierEndpoint$new(verbs, endpoint, e, private$envir, prior, srcref))
        }

      }
    },
    addEndpoint = function(verbs, uri, expr){
      self$endpoints <- c(self$endpoints, RapierEndpoint$new(verbs, uri, expr, private$envir))
      invisible(self)
    }
  ),
  private = list(
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
