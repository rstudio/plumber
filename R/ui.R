#' @include globals.R

# Mount OpenAPI and UI
#' @noRd
mount_ui <- function(pr, host, port, ui_info, callback) {

  # return early if not enabled
  if (!isTRUE(ui_info$enabled)) {
    return()
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
  mount_openapi(pr, api_url)

  # Mount UIs
  if (isTRUE(length(.globals$UIs$mount)==0L)) {
    message("No UI available in namespace. See help(add_ui).")
    return()
  }
  ui_mount <- .globals$UIs$mount[[ui_info$ui]]
  if (!is.null(ui_mount)) {
    ui_url <- do.call(ui_mount, c(list(pr, api_url), ui_info$args))
    message("Running ", ui_info$ui, " UI at ", ui_url, sep = "")
  } else {
    message("Unknown user interface \"", ui_info$ui,"\". Maybe try library(", ui_info$ui,").")
    return()
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
    return()
  }

  # Unount openAPI spec paths openapi.json
  unmount_openapi(pr)

  # Mount UIs
  ui_unmount <- .globals$UIs$unmount[[ui_info$ui]]
  if (!is.null(ui_unmount)) {
    ui_unmount(pr = pr)
  }
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mount_openapi <- function(pr, api_url) {

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
        api_url <- sub(paste0("__(", paste0(names(.globals$UIs$mount), collapse = "|"),")__/$"), "", api_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_url))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())
  pr$handle("GET", "/openapi.yaml", openapi_fun, serializer = serializer_yaml())

  invisible()

}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
unmount_openapi <- function(pr) {

  pr$removeHandle("GET", "/openapi.json")
  pr$removeHandle("GET", "/openapi.yaml")
  invisible()

}

#' Add UI for plumber to use
#' @param ui A list of that plumber can use to mount
#' a UI.
#' @details [add_ui()] is used by package like `rapidoc`, `redoc` and `swagger`.
#' When you load those package, it calls [add_ui()] to provide a user
#' interface that can interpret your plumber OpenAPI Specifications.
#'
#' `ui` list expects the following values
#' \describe{
#' \item{package}{Name of the package required for the UI.}
#' \item{name}{Name of the UI.}
#' \item{index}{A function that returns the HTML content of the landing page of the UI.}
#' \item{static}{A function that returns the path to the assets (images, javascript, css, fonts) the UI will use.}
#' }
#' @export
add_ui <- function(ui) {

  stopifnot(is.list(ui))
  stopifnot(is.character(ui$package) && length(ui$package) == 1L)

  if (!requireNamespace(ui$package, quietly = TRUE)) {
    stop(ui$package, " must be installed for the ", ui$name," UI to be displayed")
  }

  stopifnot(is.character(ui$name) && length(ui$name) == 1L)
  stopifnot(is.function(ui$static))
  stopifnot(is.function(ui$index))
  ui_root <- paste0("/__", ui$name, "__/")
  ui_path <- paste0(ui_root, c("index.html", ""))

  mount_ui_func <- function(pr, api_url, ...) {

    ui_url <- paste0(api_url, ui_root)

    ui_index <- function() {
      ui$index(...)
    }
    for (path in ui_path) {
      pr$handle("GET", path, ui_index,  serializer = serializer_html())
    }
    pr$mount(ui_root, PlumberStatic$new(ui$static(...)))
    return(ui_url)
  }
  unmount_ui_func <- function(pr) {
    for (path in ui_path) {
      pr$removeHandle("GET", path)
    }
    pr$unmount(ui_root)
    invisible()
  }

  .globals$UIs$mount[[ui$name]] <- mount_ui_func
  .globals$UIs$unmount[[ui$name]] <- unmount_ui_func

  invisible()
}

# TODO: Remove once UI load code moved to respective UI package
swagger_ui <- list(
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

#' @noRd
addUIs_onLoad <- function() {
  add_ui(swagger_ui)
}