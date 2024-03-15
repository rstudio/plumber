#' @import options
options::set_option_name_fn(function(package, name) {
  paste0(package, ".", name)
})

options::set_envvar_name_fn(function(package, name) {
  gsub("[^A-Z0-9]", "_", toupper(paste0(package, "_", name)))
})

options::define_option(
  option = "port",
  default = NULL,
  desc = paste(
    "Port Plumber will attempt to use to start http server.",
    "If the port is already in use, server will not be able to start."
  )
)

options::define_option(
  option = "docs",
  default = TRUE,
  desc = paste(
    'Name of the visual documentation interface to use.',
    'Default `TRUE` is the same as `"swagger"`.'
  )
)

options::define_option(
  option = "docs.callback",
  default = NULL,
  desc = paste(
    "A function. Called with a single parameter corresponding to the visual documentation url",
    "after Plumber server is ready. This can be used by RStudio to open the docs when then API",
    "is ran from the editor."
  )
)

options::define_option(
  option = "trailingSlash",
  default = FALSE,
  desc = paste(
    "Logical value which allows the router to redirect any request that has a matching route with",
    "a trailing slash. For example, if set to `TRUE` and the GET route `/test/` existed, then a",
    "GET request of `/test?a=1` would redirect to `/test/?a=1`.",
    "This option will default to `TRUE` in a future release."
  ),
  envvar_fn = options::envvar_is_true()
)

options::define_option(
  option = "methodNotAllowed",
  default = TRUE,
  desc = paste(
    '`r lifecycle::badge("experimental")` Logical value which allows the router to notify that an',
    "unavailable method was requested, but a different request method is allowed. For example, if",
    "set to `TRUE` and the GET route `/test` existed, then a POST request of `/test` would receive",
    "a 405 status and the allowed methods."
  ),
  envvar_fn = options::envvar_is_true()
)

options::define_option(
  option = "apiURL",
  default = NULL,
  desc = paste(
    "Server urls for OpenAPI Specification respecting pattern `scheme://host:port/path`.",
    "Other `api*` options will be ignored when set."
  )
)

options::define_option(
  option = "apiScheme",
  default = "http",
  desc = paste(
    "Scheme used to build OpenAPI url and server url for OpenAPI Specification."
  )
)

options::define_option(
  option = "apiHost",
  default = character(),
  desc = paste(
    "Host used to build docs url and server url for OpenAPI Specification.",
    "Defaults to `host` defined by `run` method when used inside a running router."
  )
)

options::define_option(
  option = "apiPort",
  default = character(),
  desc = paste(
    "Port used to build OpenAPI url and server url for OpenAPI Specification.",
    "Defaults to `port` defined by `run` method when used inside a running router."
  )
)

options::define_option(
  option = "apiPath",
  default = character(),
  desc = "Path used to build OpenAPI url and server url for OpenAPI Specification."
)

options::define_option(
  option = "maxRequestSize",
  default = 0,
  desc = paste(
    "Maximum length in bytes of request body.",
    "Body larger than maximum are rejected with http error 413.",
    "`0` means unlimited size. Defaults to `0`."
  )
)

options::define_option(
  option = "sharedSecret",
  default = NULL,
  desc = paste(
    "Shared secret used to filter incoming request. When `NULL`, secret is not validated.",
    "Otherwise, Plumber compares secret with http header `PLUMBER_SHARED_SECRET`.",
    "Failure to match results in http error 400."
  )
)

options::define_option(
  option = "legacyRedirects",
  default = TRUE,
  desc = paste(
    "Plumber will redirect legacy route `/__swagger__/` and `/__swagger__/index.html` to",
    "`../__docs__/` and `../__docs__/index.html`.",
    "You can disable this behavior by setting this option to `FALSE`."
  ),
  envvar_fn = options::envvar_is_true()
)

#' @eval options::as_roxygen_docs()
NULL

#' Plumber options
#'
#' Options that change behaviors can be set globally with
#' \code{\link[base:options]{options}}, \code{\link[plumber:options_plumber]{options_plumber}}
#' or with environment variables.
#'
#' @param ... Ignored. Should be empty
#' @param port,docs,docs.callback,trailingSlash,methodNotAllowed,apiScheme,apiHost,apiPort,apiPath,apiURL,maxRequestSize,sharedSecret,legacyRedirects
#' See Options.
#' @return Invisibly an options list from `options::opts(env = "plumber")`.
#' @export
#' @keywords internal
#' @rdname options
options_plumber <- function(
  ...,
  port                 = getOption("plumber.port"),
  docs                 = getOption("plumber.docs"),
  docs.callback        = getOption("plumber.docs.callback"),
  trailingSlash        = getOption("plumber.trailingSlash"),
  methodNotAllowed     = getOption("plumber.methodNotAllowed"),
  apiURL               = getOption("plumber.apiURL"),
  apiScheme            = getOption("plumber.apiScheme"),
  apiHost              = getOption("plumber.apiHost"),
  apiPort              = getOption("plumber.apiPort"),
  apiPath              = getOption("plumber.apiPath"),
  maxRequestSize       = getOption("plumber.maxRequestSize"),
  sharedSecret         = getOption("plumber.sharedSecret"),
  legacyRedirects      = getOption("plumber.legacyRedirects")
) {
  ellipsis::check_dots_empty()

  # Make sure all fallback options are disabled
  if (!missing(docs.callback) && is.null(docs.callback)) {
    options("plumber.swagger.url" = NULL)
  }

  options(
    plumber.port                 =   port,
    plumber.docs                 =   docs,
    plumber.docs.callback        =   docs.callback,
    plumber.trailingSlash        =   trailingSlash,
    plumber.methodNotAllowed     =   methodNotAllowed,
    plumber.apiURL               =   apiURL,
    plumber.apiScheme            =   apiScheme,
    plumber.apiHost              =   apiHost,
    plumber.apiPort              =   apiPort,
    plumber.apiPath              =   apiPath,
    plumber.maxRequestSize       =   maxRequestSize,
    plumber.sharedSecret         =   sharedSecret,
    plumber.legacyRedirects      =   legacyRedirects
  )

  invisible(options::opts(env = "plumber"))

}
