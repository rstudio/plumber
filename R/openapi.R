#' Convert router to/from OpenAPI specifications
#' @rdname openapi
#' @param plumber A plumber router or a plumbable file or directory
#' @description These functions are used to convert between OpenAPI
#' specifications and plumber file. Plumber only supports a limited
#' set of OpenAPI specifications.
#' @param output An optional filename where to write specifications.
#' @details OpenAPI is a specifications to describe API. More info
#' can be found at (https://swagger.io/specification/)
#' @examples
#' pr <- plumber$new()
#' toOpenAPI(pr)
toOpenAPI <- function(plumber, output = NULL) {
  if (!inherits(pr, "plumber")) {
    if (file.exists(plumber) && file.info(plumber)$isdir) {
      pr <- plumb(dir = plumber)
    } else {
      pr <- plumb(plumber)
    }
  }
  spec <- pr$openAPIFile()
  open_api_url <- {
    apiURL1 <- getOption("plumber.apiURL")
    apiURL2 <- urlHost(scheme = getOption("plumber.apiScheme", ""),
                       host   = getOption("plumber.apiHost", ""),
                       port   = getOption("plumber.apiPort", ""),
                       path   = getOption("plumber.apiPath", ""),
                       changeHostLocation = TRUE)
    priorizeProperty(apiURL1, apiURL2)
  }

  spec$servers$url <- open_api_url
  spec$servers$description <- "OpenAPI"

  spec <- toJSON(spec, auto_unbox = TRUE)
  if (!is.null(output)) {
    return(writeLines(spec, output))
  }
  return(spec)
}

#' @rdname openapi
#' @param openapi an OpenAPI specifications string, URL or file
fromOpenAPI <- function(openapi, format = c("json", "yml")) {
  format <- match.arg(format)
  if (tools::file_ext(openapi) == "yml" || format == "yml") {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("The yaml package is not available but is required in order to parse yaml specifications.\ninstall.packages(\"yaml\")",
           call. = FALSE)
    }
    spec <- yaml::read_yaml(openapi)
  } else if (jsonlite::validate(readLines(openapi, warn = FALSE))) {
    spec <- fromJSON(openapi)
  } else {
    stop("Invalid", format, "file.")
  }

}
