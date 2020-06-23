#' @include globals.R

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
  if (isTRUE(ui)) {
    ui <- getOption("plumber.ui", "swagger")
  }
  interface <- ui[1]
  ui_mount <- .globals$interfaces[[interface]]
  if (!is.null(ui_mount)) {
    ui_url <- ui_mount(pr, api_url, ...)
    message("Running ", interface, " UI at ", ui_url, sep = "")
  } else {
    message("Ignored unknown user interface ", interface,". Supports ",
            paste0('"', names(.globals$interfaces), '"', collapse = ", "))
  }

  # Use callback when defined
  if (is.function(callback)) {
    callback(ui_url)
  }

  return(invisible())

}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mountOpenAPI <- function(pr, api_url) {

  spec <- pr$swaggerFile()

  # Create a function that's hardcoded to return the OpenAPI specification -- regardless of env.
  openapi_fun <- function(req) {
    # use the HTTP_REFERER so RSC can find the swagger location to ask
    ## (can't directly ask for 127.0.0.1)
    if (is.null(getOption("plumber.apiURL")) &&
        is.null(getOption("plumber.apiHost"))) {
      if (is.null(req$HTTP_REFERER)) {
        # Prevent leaking host and port if option is not set
        api_url <- character(1)
      }
      else {
        # Use HTTP_REFERER as fallback
        api_url <- req$HTTP_REFERER
        api_url <- sub("index\\.html$", "", api_url)
        api_url <- sub(paste0("__(", paste0(names(.globals$interfaces), collapse = "|"),")__/$"), "", api_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_url, description = "OpenAPI"))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())

  return(invisible())

}

#' Mount Interface UI
#' @noRd
mountInterfaces <- function(interface) {
  mountInterface <- function(pr, api_url, ...) {
    if (!requireNamespace(interface$package, quietly = TRUE)) {
      stop(interface$package, " must be installed for the ", interface$name," UI to be displayed")
    }

    interfacePath <- paste0("/__", tolower(interface$name), "__/")
    interfaceUrl <- paste0(api_url, interfacePath)

    html_content <- interface$index(...)
    interface_index <- function() {
      html_content
    }
    for (path in paste0(interfacePath, c("index.html", ""))) {
      pr$handle(
        "GET", path, interface_index,
        serializer = serializer_html()
      )
    }
    pr$mount(interfacePath, PlumberStatic$new(interface$static()))
    return(interfaceUrl)
  }
  .globals$interfaces[[interface$name]] <- mountInterface
}

swaggerInterface <- list(
  package = "swagger",
  name = "swagger",
  index = function() {
    swagger::swagger_spec(
      api_path = 'window.location.origin + window.location.pathname.replace(/\\(__swagger__\\\\/|__swagger__\\\\/index.html\\)$/, "") + "openapi.json"',
      version = "3"
    )
  },
  static = swagger::swagger_path
)

redocInterface <- list(
  package = "redoc",
  name = "redoc",
  index = function(redoc_options = structure(list(), names = character())) {
    redoc::redoc_spec(
      spec_url = "\' + window.location.origin + window.location.pathname.replace(/\\(__redoc__\\\\/|__redoc__\\\\/index.html\\)$/, '') + 'openapi.json' + \'",
      redoc_options = redoc_options
    )
  },
  static = redoc::redoc_path
)

mountInterfaces(swaggerInterface)
mountInterfaces(redocInterface)
