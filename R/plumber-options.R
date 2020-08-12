#' Plumber options
#'
#' There are a number of global options that affect Plumber's behavior. These can
#' be set globally with [options()] or with [options_plumber()]. Options set using
#' [options_plumber()] should not include the `plumber.` prefix.
#'
#' \describe{
#' \item{`plumber.apiURL`}{UI url and server urls for OpenAPI Specification respecting
#' pattern `scheme://host:port/path`. Other UI url options will be ignored when set.}
#' \item{`plumber.apiScheme`}{Scheme used to build UI url and server url for
#' OpenAPI Specification. Defaults to `http`, or an empty string
#' when used outside a running router}
#' \item{`plumber.apiHost`}{Host used to build UI url and server url for
#' OpenAPI Specification. Defaults to `host` defined by `run` method, or an empty string
#' when used outside a running router}
#' \item{`plumber.apiPort`}{Port used to build UI url and server url for
#' OpenAPI Specification. Defaults to `port` defined by `run` method, or an empty string
#' when used outside a running router}
#' \item{`plumber.apiPath`}{Path used to build UI url and server url for
#' OpenAPI Specification. Defaults to an empty string}
#' \item{`plumber.maxRequestSize`}{Maximum length in bytes of request body. Body larger
#' than maximum are rejected with http error 413. `0` means unlimited size. Defaults to `0`}
#' \item{`plumber.postBody`}{Copy post body content to `req$postBody` using system encoding.
#' This should be set to `FALSE` if you do not need it. Default is `TRUE` to preserve compatibility with
#' previous version behavior. Defaults to `TRUE`}
#' \item{`plumber.port`}{Port Plumber will attempt to use to start http server.
#' If the port is already in use, server will not be able to start. Defaults to `NULL`}
#' \item{`plumber.sharedSecret`}{Shared secret used to filter incoming request.
#' When `NULL`, secret is not validated. Otherwise, Plumber compares secret with http header
#' `PLUMBER_SHARED_SECRET`. Failure to match results in http error 400. Defaults to `NULL`}
#' \item{`plumber.ui`}{Name of the UI interface to use. Defaults to `TRUE`}
#' \item{`plumber.ui.callback`}{A function. Called with
#' a single parameter corresponding to ui url after Plumber server is ready. This can be used
#' by RStudio to open UI when API is ran for the editor. Defaults to option `plumber.swagger.url`}
#' }
#'
#' @param apiScheme,apiHost,apiPort,apiPath,apiURL,maxRequestSize,postBody,port,sharedSecret,ui,ui.callback See details
#' @return
#' The complete, prior set of [options()] values.
#' If a particular parameter is not supplied, it will return the current value.
#' If no parameters are supplied, all returned values will be the current [options()] values.
#' @export
options_plumber <- function(
  apiScheme            = getOption("plumber.apiScheme"),
  apiHost              = getOption("plumber.apiHost"),
  apiPort              = getOption("plumber.apiPort"),
  apiPath              = getOption("plumber.apiPath"),
  apiURL               = getOption("plumber.apiURL"),
  maxRequestSize       = getOption("plumber.maxRequestSize"),
  postBody             = getOption("plumber.postBody"),
  port                 = getOption("plumber.port"),
  sharedSecret         = getOption("plumber.sharedSecret"),
  ui                   = getOption("plumber.ui"),
  ui.callback          = getOption("plumber.ui.callback")
) {
  options(
    plumber.apiScheme = apiScheme,
    plumber.apiHost = apiHost,
    plumber.apiPort = apiPort,
    plumber.apiPath = apiPath,
    plumber.apiURL = apiURL,
    plumber.maxRequestSize = maxRequestSize,
    plumber.postBody = postBody,
    plumber.port = port,
    plumber.sharedSecret = sharedSecret,
    plumber.ui = ui,
    plumber.ui.callback = ui.callback
  )
}
