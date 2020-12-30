#' Plumber options
#'
#' There are a number of global options that affect Plumber's behavior. These can
#' be set globally with [options()] or with [options_plumber()]. Options set using
#' [options_plumber()] should not include the `plumber.` prefix.
#'
#' \describe{
#' \item{`plumber.port`}{Port Plumber will attempt to use to start http server.
#' If the port is already in use, server will not be able to start. Defaults to `NULL`.}
#' \item{`plumber.docs`}{Name of the visual documentation interface to use. Defaults to `TRUE`, which will use `"swagger"`.}
#' \item{`plumber.docs.callback`}{A function. Called with
#' a single parameter corresponding to the visual documentation url after Plumber server is ready. This can be used
#' by RStudio to open the docs when then API is ran from the editor. Defaults to option `NULL`.}
#' \item{`plumber.apiURL`}{Server urls for OpenAPI Specification respecting
#' pattern `scheme://host:port/path`. Other `api*` options will be ignored when set.}
#' \item{`plumber.apiScheme`}{Scheme used to build OpenAPI url and server url for
#' OpenAPI Specification. Defaults to `http`, or an empty string
#' when used outside a running router.}
#' \item{`plumber.apiHost`}{Host used to build docs url and server url for
#' OpenAPI Specification. Defaults to `host` defined by `run` method, or an empty string
#' when used outside a running router.}
#' \item{`plumber.apiPort`}{Port used to build OpenAPI url and server url for
#' OpenAPI Specification. Defaults to `port` defined by `run` method, or an empty string
#' when used outside a running router.}
#' \item{`plumber.apiPath`}{Path used to build OpenAPI url and server url for
#' OpenAPI Specification. Defaults to an empty string.}
#' \item{`plumber.maxRequestSize`}{Maximum length in bytes of request body. Body larger
#' than maximum are rejected with http error 413. `0` means unlimited size. Defaults to `0`.}
#' \item{`plumber.sharedSecret`}{Shared secret used to filter incoming request.
#' When `NULL`, secret is not validated. Otherwise, Plumber compares secret with http header
#' `PLUMBER_SHARED_SECRET`. Failure to match results in http error 400. Defaults to `NULL`.}
#' \item{`plumber.legacyRedirects`}{Plumber will redirect legacy route `/__swagger__/` and
#' `/__swagger__/index.html` to `../__docs__/` and `../__docs__/index.html`. You can disable this
#' by settings this option to `FALSE`. Defaults to `TRUE`}
#' }
#'
#' @param port,docs,docs.callback,apiScheme,apiHost,apiPort,apiPath,apiURL,maxRequestSize,sharedSecret,legacyRedirects See details
#' @return
#' The complete, prior set of [options()] values.
#' If a particular parameter is not supplied, it will return the current value.
#' If no parameters are supplied, all returned values will be the current [options()] values.
#' @export
options_plumber <- function(
  port                 = getOption("plumber.port"),
  docs                 = getOption("plumber.docs"),
  docs.callback        = getOption("plumber.docs.callback"),
  apiURL               = getOption("plumber.apiURL"),
  apiScheme            = getOption("plumber.apiScheme"),
  apiHost              = getOption("plumber.apiHost"),
  apiPort              = getOption("plumber.apiPort"),
  apiPath              = getOption("plumber.apiPath"),
  maxRequestSize       = getOption("plumber.maxRequestSize"),
  sharedSecret         = getOption("plumber.sharedSecret"),
  legacyRedirects      = getOption("plumber.legacyRedirects")
) {
  options(
    plumber.apiScheme = apiScheme,
    plumber.apiHost = apiHost,
    plumber.apiPort = apiPort,
    plumber.apiPath = apiPath,
    plumber.apiURL = apiURL,
    plumber.maxRequestSize = maxRequestSize,
    plumber.port = port,
    plumber.sharedSecret = sharedSecret,
    plumber.docs = docs,
    plumber.docs.callback = docs.callback,
    plumber.legacyRedirects = legacyRedirects
  )
}
