#' @include globals.R

# Mount OpenAPI and UI
#' @noRd
mount_ui <- function(pr, host, port, ui_info, callback) {

  # return early if not enabled
  if (!isTRUE(ui_info$enabled)) {
    return(NULL)
  }

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
  mount_open_api(pr, api_url)

  # Mount UIs
  if (isTRUE(length(.globals$interfaces$mount)==0L)) {
    message("No user interface loaded in namespace.")
    return(NULL)
  }
  ui_mount <- .globals$interfaces$mount[[ui_info$ui]]
  if (!is.null(ui_mount)) {
    ui_url <- do.call(ui_mount, c(list(pr, api_url), ui_info$args))
    message("Running ", ui_info$ui, " UI at ", ui_url, sep = "")
  } else {
    message("Unknown user interface \"", ui_info$ui,"\". ",
            ". Maybe try library(", ui_info$ui,").")
    return(NULL)
  }

  # Use callback when defined
  if (is.function(callback)) {
    callback(ui_url)
  }

  invisible()

}

# Unmount OpenAPI and UI
#' @noRd
unmount_ui <- function(pr, ui_info) {

  # return early if not enabled
  if (!isTRUE(ui_info$enabled)) {
    return(NULL)
  }

  # Unount openAPI spec paths openapi.json
  unmount_open_api(pr)

  # Mount UIs
  ui_unmount <- .globals$interfaces$unmount[[ui_info$ui]]
  if (!is.null(ui_unmount)) {
    ui_unmount(pr = pr)
  }
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mount_open_api <- function(pr, api_url) {

  spec <- pr$apiSpec()

  # Create a function that's hardcoded to return the OpenAPI specification -- regardless of env.
  openapi_fun <- function(req) {
    # use the HTTP_REFERER so RSC can find the UI location to ask
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
        api_url <- sub(paste0("__(", paste0(names(.globals$interfaces$mount), collapse = "|"),")__/$"), "", api_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_url))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())

  return(NULL)

}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
unmount_open_api <- function(pr) {

  pr$removeHandle("GET", "/openapi.json")
  return(NULL)

}

#' Mount Interface UI
#' @param interface An interface (list) that plumber can use to mount
#' a UI.
#' @export
mount_interface <- function(interface) {

  stopifnot(is.list(interface))
  stopifnot(is.character(interface$package) && length(interface$package) == 1L)

  if (!requireNamespace(interface$package, quietly = TRUE)) {
    stop(interface$package, " must be installed for the ", interface$name," UI to be displayed")
  }

  stopifnot(is.character(interface$name) && length(interface$name) == 1L)
  stopifnot(is.function(interface$static))
  stopifnot(is.function(interface$index))
  interface_path <- paste0("/__", interface$name, "__/")
  handle_paths <- paste0(interface_path, c("index.html", ""))

  mount_interface_func <- function(pr, api_url, ...) {
    if (!requireNamespace(interface$package, quietly = TRUE)) {
      stop(interface$package, " must be installed for the ", interface$name," UI to be displayed")
    }

    interface_url <- paste0(api_url, interface_path)

    interface_index <- function() {
      interface$index(...)
    }
    for (path in handle_paths) {
      pr$handle(
        "GET", path, interface_index,
        serializer = serializer_html()
      )
    }
    pr$mount(interface_path, PlumberStatic$new(interface$static(...)))
    return(interface_url)
  }
  unmount_interface_func <- function(pr) {
    for (path in handle_paths) {
      pr$removeHandle("GET", path)
    }
    pr$unmount(interface_path)
    return(NULL)
  }

  .globals$interfaces$mount[[interface$name]] <- mount_interface_func
  .globals$interfaces$unmount[[interface$name]] <- unmount_interface_func

  return(NULL)
}

swagger_interface <- list(
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

mount_interface(swagger_interface)
