#' @include globals.R

# Mount OpenAPI and UI
#' @noRd
mountUI <- function(pr, host, port, ui_info, callback) {

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
  ui_mount <- .globals$interfaces$mount[[ui_info$ui]]
  if (!is.null(ui_mount)) {
    ui_url <- do.call(ui_mount, c(list(pr, api_url), ui_info$args))
    message("Running ", ui_info$ui, " UI at ", ui_url, sep = "")
  } else {
    message("Ignored unknown user interface ", ui_info$ui,". Supports ",
            paste0('"', names(.globals$interfaces), '"', collapse = ", "))
  }

  # Use callback when defined
  if (is.function(callback)) {
    callback(ui_url)
  }

  return(invisible())

}

# Unmount OpenAPI and UI
#' @noRd
unmountUI <- function(pr, ui_info) {
  # Unount openAPI spec paths openapi.json
  unmountOpenAPI(pr)

  # Mount UIs
  ui_unmount <- .globals$interfaces$unmount[[ui_info$ui]]
  if (!is.null(ui_unmount)) {
    ui_unmount(pr)
  }
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mountOpenAPI <- function(pr, api_url) {

  spec <- pr$apiSpec()

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

    utils::modifyList(list(servers = list(list(url = api_url))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())

  return(invisible())

}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
unmountOpenAPI <- function(pr) {

  pr$removeHandle("GET", "/openapi.json")

}

#' Mount Interface UI
#' @noRd
mountInterface <- function(interface) {

  stopifnot(is.list(interface))
  stopifnot(is.character(interface$package) && length(interface$package) == 1L)

  if (!requireNamespace(interface$package, quietly = TRUE)) {
    stop(interface$package, " must be installed for the ", interface$name," UI to be displayed")
  }

  stopifnot(is.character(interface$name) && length(interface$name) == 1L)
  stopifnot(is.function(interface$static))
  stopifnot(is.function(interface$index))
  interfacePath <- paste0("/__", interface$name, "__/")
  handlePaths <- paste0(interfacePath, c("index.html", ""))

  mountInterfaceFunc <- function(pr, api_url, ...) {
    if (!requireNamespace(interface$package, quietly = TRUE)) {
      stop(interface$package, " must be installed for the ", interface$name," UI to be displayed")
    }

    interfaceUrl <- paste0(api_url, interfacePath)

    interface_index <- function() {
      interface$index(...)
    }
    for (path in handlePaths) {
      pr$handle(
        "GET", path, interface_index,
        serializer = serializer_html()
      )
    }
    pr$mount(interfacePath, PlumberStatic$new(interface$static(...)))
    return(interfaceUrl)
  }
  unmountInterfaceFunc <- function(pr) {
    for (path in handlePaths) {
      pr$removeHandle("GET", path)
    }
    pr$unmount(interfacePath)
    return(NULL)
  }
  .globals$interfaces$mount[[interface$name]] <- mountInterfaceFunc
  .globals$interfaces$unmount[[interface$name]] <- unmountInterfaceFunc
}

swaggerInterface <- list(
  package = "swagger",
  name = "swagger",
  index = function(version = "3", ...) {
    swagger::swagger_spec(
      api_path = 'window.location.origin + window.location.pathname.replace(/\\(__swagger__\\\\/|__swagger__\\\\/index.html\\)$/, "") + "openapi.json"',
      version = version
    )
  },
  static = function(version = "3", ...) {
    swagger::swagger_path(version)
  }
)

redocInterface <- list(
  package = "redoc",
  name = "redoc",
  index = function(redoc_options = structure(list(), names = character()), ...) {
    redoc::redoc_spec(
      spec_url = "\' + window.location.origin + window.location.pathname.replace(/\\(__redoc__\\\\/|__redoc__\\\\/index.html\\)$/, '') + 'openapi.json' + \'",
      redoc_options = redoc_options
    )
  },
  static = function(...) {
    redoc::redoc_path()
  }
)

mountInterface(swaggerInterface)
mountInterface(redocInterface)
