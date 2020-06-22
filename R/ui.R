# Mount OpenAPI and UI
#' @noRd
mountUI <- function(pr, host, port, ui, callback, ...) {

  # Build api url
  api_url <- getOption(
    "plumber.apiURL",
    urlHost(
      scheme = getOption("plumber.apiScheme", "http"),
      host   = getOption("plumber.apiHost", host),
      port   = getOption("plumber.apiPort", port),
      path   = getOption("plumber.apiPath", ""),
      changeHostLocation = TRUE
    )
  )

  # Mount openAPI spec paths openapi.json
  mountOpenAPI(pr, api_url)

  # Mount UIs
  if (isTRUE(ui)) ui <- getOption("plumber.ui", "Swagger")
  for (interface in ui) {
    ui_mount <- .globals$interfaces[[interface]]
    if (!is.null(ui_mount)) {
      ui_url <- ui_mount(pr, api_url,...)
      message("Running ", interface, " UI at ", ui_url, sep = "")
    } else {
      message("Ignored unknown user interface ", interface,". Supports ",
              paste0('"', names(.globals$interfaces), '"', collapse = ", "))
    }
  }

  # Use callback when defined
  if (is.function(callback)) {
    callback(ui_url)
  }

  return(invisible())

}

#' Mount OpenAPI spec to a plumber router
#' @noRd
mountOpenAPI <- function(pr, api_server_url) {

  spec <- pr$openAPISpec()

  # Create a function that's hardcoded to return the OpenAPI specification -- regardless of env.
  openapi_fun <- function(req) {
    # use the HTTP_REFERER so RSC can find the swagger location to ask
    ## (can't directly ask for 127.0.0.1)
    if (isFALSE(getOption("plumber.apiURL", FALSE)) &&
        isFALSE(getOption("plumber.apiHost", FALSE))) {
      if (is.null(req$HTTP_REFERER)) {
        # Prevent leaking host and port if option is not set
        api_server_url <- character(1)
      }
      else {
        # Use HTTP_REFERER as fallback
        api_server_url <- req$HTTP_REFERER
        api_server_url <- sub("index\\.html$", "", api_server_url)
        api_server_url <- sub("__[swagerdoc]+__/$", "", api_server_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_server_url, description = "OpenAPI"))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())

  return(invisible())

}

#' Mount Swagger UI
#' @noRd
mountSwagger <- function(pr, url, ...) {
  if (!requireNamespace("swagger", quietly = TRUE)) {
    stop("swagger must be installed for the Swagger UI to be displayed")
  }

  swaggerUrl <- paste0(url, "/__swagger__/")

  swagger_index <- function(...) {
    swagger::swagger_spec(
      'window.location.origin + window.location.pathname.replace(/\\(__swagger__\\\\/|__swagger__\\\\/index.html\\)$/, "") + "openapi.json"',
      version = "3"
    )
  }
  for (path in c("/__swagger__/index.html", "/__swagger__/")) {
    pr$handle(
      "GET", path, swagger_index,
      serializer = serializer_html()
    )
  }
  pr$mount("/__swagger__", PlumberStatic$new(swagger::swagger_path()))

  return(swaggerUrl)
}

#' @include globals.R
.globals$interfaces[["swagger"]] <- mountSwagger
.globals$interfaces[["Swagger"]] <- mountSwagger

#' Mount Redoc UI
#' @noRd
mountRedoc <- function(pr, url, redoc_options = structure(list(), names = character())) {
  if (!requireNamespace("redoc", quietly = TRUE)) {
    stop("redoc must be installed for the Redoc UI to be displayed")
  }

  redocUrl <- paste0(url, "/__redoc__/")

  redoc_index <- function(...) {
    redoc::redoc_spec(
      "\' + window.location.origin + window.location.pathname.replace(/\\(__redoc__\\\\/|__redoc__\\\\/index.html\\)$/, '') + 'openapi.json' + \'",
      redoc_options)
  }
  for (path in c("/__redoc__/index.html", "/__redoc__/")) {
    pr$handle(
      "GET", path, redoc_index,
      serializer = serializer_html()
    )
  }
  pr$mount("/__redoc__", PlumberStatic$new(redoc::redoc_path()))

  return(redocUrl)
}

.globals$interfaces[["redoc"]] <- mountRedoc
.globals$interfaces[["Redoc"]] <- mountRedoc
