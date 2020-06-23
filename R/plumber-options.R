
#' How to use Plumber options
#'
#' @section Options:
#' There are a number of global options that affect Plumber's behavior. These can
#' be set globally with [options()] or with [options_plumber()].
#'
#' \describe{
#' \item{plumber.apiHost (defaults to `host` defined by `run` method, or an empty string
#' when used outside a running router)}{Host used to build UI url and server url for
#' OpenAPI specification.}
#' \item{plumber.debug (defaults to `FALSE`)}{Provides more insight into your API errors. Alternatively,
#' use parameter `debug` of plumber router `run` method}
#' \item{plumber.maxRequestSize (defaults to `0`)}{Maximum length in bytes of request body. Body larger
#' than maximum are rejected with http error 413. `0` means unlimited size.}
#' \item{plumber.postBody (defaults to `TRUE`)}{Copy post body content to `req$postBody` using system encoding.
#' This should be set to `FALSE` if you do not need it. Default is `TRUE` to preserve compatibility with
#' previous version behavior.}
#' \item{plumber.port (defaults to `NULL`)}{Port Plumber will attempt to use to start http server.
#' If the port is already in use, server will not be able to start.}
#' \item{plumber.sharedSecret (defaults to `NULL`)}{Shared secret used to filter incoming request.
#' When `NULL`, secret is not validated. Otherwise, Plumber compares secret with http header
#' `PLUMBER_SHARED_SECRET`. Failure to match results in http error 400.}
#' \item{plumber.swagger.url (defaults to `NULL`)}{A function. Called with
#' a single parameter corresponding to ui url after Plumber server is ready. This can be used
#' by RStudio to open UI when API is ran for the editor.}
#' }
#' @aliases plumber-options
"_PACKAGE"

#' Set plumber options
#' @param apiHost see [plumber-options]
#' @param debug see [plumber-options]
#' @param maxRequestSize see [plumber-options]
#' @param postBody see [plumber-options]
#' @param port see [plumber-options]
#' @param sharedSecret see [plumber-options]
#' @param swagger.url see [plumber-options]
#' @details
#' Sets plumber options. Call without arguments to get current
#' values.
#' @export
options_plumber <- function(
  apiHost              = getOption("plumber.apiHost"),
  debug                = getOption("plumber.debug"),
  maxRequestSize       = getOption("plumber.maxRequestSize"),
  postBody             = getOption("plumber.postBody"),
  port                 = getOption("plumber.port"),
  sharedSecret         = getOption("plumber.sharedSecret"),
  swagger.url          = getOption("plumber.swagger.url")
) {
  options(
    plumber.apiHost = apiHost,
    plumber.debug = debug,
    plumber.maxRequestSize = maxRequestSize,
    plumber.postBody = postBody,
    plumber.port = port,
    plumber.sharedSecret = sharedSecret,
    plumber.swagger.url = swagger.url
  )
}
