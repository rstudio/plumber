
library(stringi)
library(R6)

enumerateVerbs <- function(v){
  if (identical(v, "use")){
    return(c("get", "post", "delete"))
  }
  v
}

RapierEndpoint <- R6Class(
  "RapierEndpoint",
  public = list(
    verbs = NA,
    uri = NA,
    initialize = function(verbs, uri, expr, rSource, lines){
      self$verbs <- verbs
      self$uri <- uri

      private$expr <- expr
      private$envir <- rSource
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

        while (line > 0 && (stri_startswith(private$fileLines[line], fixed="#'") || stri_trim_both(private$fileLines[line]) == "")){
          mat <- stringi::stri_match(private$fileLines[line], regex="^#'\\s*(@(get|post|use|delete)\\s+(.*)$)?")
          if (!is.na(mat[1,2])){
            # A rapier annotation, add it.
            verbs <- enumerateVerbs(mat[1,3])

            self$endpoints <- c(self$endpoints, RapierEndpoint$new(verbs, mat[1,4], e, private$envir, srcref))
            break
          }

          line <- line - 1
        }
      }
    }
  ),
  private = list(
    filename = NA,
    fileLines = NA,
    parsed = NA,
    envir = NULL
  )
)
