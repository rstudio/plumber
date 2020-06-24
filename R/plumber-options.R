
#' How to use Plumber options
#'
#' @section Options:
#' There are a number of global options that affect Plumber's behavior. These can
#' be set globally with [options()] or with [options_plumber()].
#'
#' \describe{
#' \item{plumber.apiScheme (defaults to `http`, or an empty string
#' when used outside a running router)}{Scheme used to build UI url and server url for
#' OpenAPI Specification.}
#' \item{plumber.apiHost (defaults to `host` defined by `run` method, or an empty string
#' when used outside a running router)}{Host used to build UI url and server url for
#' OpenAPI Specification.}
#' \item{plumber.apiPort (defaults to `port` defined by `run` method, or an empty string
#' when used outside a running router)}{Port used to build UI url and server url for
#' OpenAPI Specification.}
#' \item{plumber.apiPath (defaults to an empty string)}{Path used to build UI url and server url for
#' OpenAPI Specification.}
#' \item{plumber.apiURL (defaults to the combination of the above options)}{UI url and server urls for
#' OpenAPI Specification respecting pattern `scheme://host:port/path`.}
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
#' \item{plumber.ui (defaults to `TRUE`)}{Name of the UI interface to use.}
#' \item{plumber.ui.callback (defaults to option `plumber.swagger.url`)}{A function. Called with
#' a single parameter corresponding to ui url after Plumber server is ready. This can be used
#' by RStudio to open UI when API is ran for the editor.}
#' }
#' @aliases plumber-options
"_PACKAGE"

#' Set plumber options
#' @param apiScheme see [plumber-options]
#' @param apiHost see [plumber-options]
#' @param apiPort see [plumber-options]
#' @param apiPath see [plumber-options]
#' @param apiURL see [plumber-options]
#' @param debug see [plumber-options]
#' @param maxRequestSize see [plumber-options]
#' @param postBody see [plumber-options]
#' @param port see [plumber-options]
#' @param sharedSecret see [plumber-options]
#' @param swagger.url see [plumber-options]
#' @param ui see [plumber-options]
#' @param ui.callback see [plumber-options]
#' @details
#' Sets plumber options. Call without arguments to get current
#' values.
#' @export
options_plumber <- function(
  apiScheme            = getOption("plumber.apiScheme"),
  apiHost              = getOption("plumber.apiHost"),
  apiPort              = getOption("plumber.apiPort"),
  apiPath              = getOption("plumber.apiPath"),
  apiURL               = getOption("plumber.apiURL"),
  debug                = getOption("plumber.debug"),
  maxRequestSize       = getOption("plumber.maxRequestSize"),
  postBody             = getOption("plumber.postBody"),
  port                 = getOption("plumber.port"),
  sharedSecret         = getOption("plumber.sharedSecret"),
  swagger.url          = getOption("plumber.swagger.url"),
  ui                   = getOption("plumber.ui"),
  ui.callback          = getOption("plumber.ui.callback")
) {
  options(
    plumber.apiScheme = apiScheme,
    plumber.apiHost = apiHost,
    plumber.apiPort = apiPort,
    plumber.apiPath = apiPath,
    plumber.apiURL = apiURL,
    plumber.debug = debug,
    plumber.maxRequestSize = maxRequestSize,
    plumber.postBody = postBody,
    plumber.port = port,
    plumber.sharedSecret = sharedSecret,
    plumber.swagger.url = swagger.url,
    plumber.ui = ui,
    plumber.ui.callback = ui.callback
  )
}
