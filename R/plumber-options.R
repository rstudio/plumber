# # Trace all options in packages, make sure all are documented
# mm <- character()
# for (f in dir("R", full.names = T)) {
#   ct <- paste0(readLines(f, warn = F), collapse = "")
#   m <- stringi::stri_match_all_regex(ct, "getOption\\([^,\\)]+,?\\)?")[[1]][,1]
#   m <- gsub("\\s", "", m)
#   if (length(m) > 0 && !is.na(m)) {
#     mm <- c(mm, m)
#   }
# }
# mm <- unique(sort(gsub("getOption|\\(|\"|,|'|\\)", "", mm)))
# mm <- paste0("#' \\item{", mm, " (defaults to `fill`)}{document})")
# writeLines(mm, "options.txt")

#' How to use Plumber options
#'
#' @section Options:
#' There are a number of global options that affect Plumber's behavior. These can
#' be set globally with `options()`.
#'
#' \describe{
#' \item{plumber.apiScheme (defaults to `http`, or an empty string
#' when used outside a running router)}{Scheme used to build UI url and server url for
#' OpenAPI specification.})
#' \item{plumber.apiHost (defaults to `host` defined by `run` method, or an empty string
#' when used outside a running router)}{Host used to build UI url and server url for
#' OpenAPI specification.})
#' \item{plumber.apiPort (defaults to `port` defined by `run` method, or an empty string
#' when used outside a running router)}{Port used to build UI url and server url for
#' OpenAPI specification.})
#' \item{plumber.apiPath (defaults to an empty string)}{Path used to build UI url and server url for
#' OpenAPI specification.})
#' \item{plumber.apiURL (defaults to the combination of the above options)}{UI url and server urls for
#' OpenAPI specification respecting pattern `scheme://host:port/path`.})
#' \item{plumber.debug (defaults to `FALSE`)}{Provides more insight into your API errors. Alternatively,
#' use parameter `debug` of plumber router `run` method})
#' \item{plumber.maxRequestSize (defaults to `0`)}{Maximum length in bytes of request body. Body larger
#' than maximum are rejected with http error 413. `0` means unlimited size.})
#' \item{plumber.port (defaults to `NULL`)}{Port Plumber will attempt to use to start http server.
#' If the port is already in use, server will not be able to start.})
#' \item{plumber.sharedSecret (defaults to `NULL`)}{Shared secret used to filter incoming request.
#' When `NULL`, secret is not validated. Otherwise, Plumber compares secret with http header
#' `PLUMBER_SHARED_SECRET`. Failure to match results in http error 400.})
#' \item{plumber.swagger.url (defaults to `NULL`)}{Legacy : same function as `plumber.ui.callback`})
#' \item{plumber.ui (defaults to `Swagger`)}{document})
#' \item{plumber.ui.callback (defaults to option `plumber.swagger.url`)}{A function. Called with
#' a single parameter corresponding to ui url after Plumber server is ready. This can be used
#' by RStudio to open UI when API is ran for the editor.})
#' }
#' @aliases plumber-options
"_PACKAGE"
