toOpenAPI <- function(plumber) {
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

  spec
}

fromOpenAPI <- function(openapi) {
  if (tools::file_ext(openapi) == "yml") {

  }
  if (!jsonlite::validate(readLines(openapi))) {
    stop("Invalid json file.")
  }
}
