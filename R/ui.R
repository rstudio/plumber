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
  if (length(registered_uis()) == 0) {
    message("No UI available in namespace. See help(register_ui).")
    return()
  }

  if (is_ui_available(ui_info$ui)) {
    ui_mount <- .globals$UIs[[ui_info$ui]]$mount
    ui_url <- do.call(ui_mount, c(list(pr, api_url), ui_info$args))
    message("Running ", ui_info$ui, " UI at ", ui_url, sep = "")
  } else {
    return()
  }

  # Use callback
  if (is.function(callback)) {
    callback(ui_url)
  }

  invisible()

}

# Check is UI is available
#' @noRd
is_ui_available <- function(ui) {
  if (isTRUE(ui %in% registered_uis())) {
    return(TRUE)
  } else {
    message("Unknown user interface \"", ui,"\". Maybe try library(", ui,").")
    return(FALSE)
  }
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
  ui_unmount <- .globals$UIs[[ui_info$ui]]$unmount
  if (length(ui_unmount) && is.function(ui_unmount)) {
    ui_unmount(pr = pr)
  }
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mount_openapi <- function(pr, api_url) {

  spec <- pr$get_api_spec()

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
        api_url <- sub("(\\?.*)?$", "", api_url)
        api_url <- sub("index\\.html$", "", api_url)
        api_url <- sub(paste0("__(", paste0(registered_uis(), collapse = "|"),")__/$"), "", api_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_url))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  for (ep in pr$endpoints[["__no-preempt__"]]) {
    if (ep$path == "/openapi.json") {
      message("Overwritting existing `/openapi.json` route. Use `$set_api_spec()` to define your OpenAPI Spec")
      break
    }
  }
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())

  invisible()
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
unmount_openapi <- function(pr) {

  pr$removeHandle("GET", "/openapi.json")
  invisible()

}

#' Add UI for plumber to use
#'
#' [register_ui()] is used by other packages like `swagger`.
#' When you load these packages, it calls [register_ui()] to provide a user
#' interface that can interpret your plumber OpenAPI Specifications.
#'
#' @param name Name of the UI
#' @param index A function that returns the HTML content of the landing page of the UI.
#'   Parameters (besides `req` and `res`) will be supplied as if it is a regular `GET` route.
#'   Default parameter values may be used when setting the ui.
#'   Be sure to see the example below.
#' @param static A function that returns the path to the static assets (images, javascript, css, fonts) the UI will use.
#'
#' @export
#' @examples
#' \dontrun{
#' # Example from the `swagger` R package
#' register_ui(
#'   name = "swagger",
#'   index = function(version = "3", ...) {
#'     swagger::swagger_spec(
#'       api_path = paste0(
#'         "window.location.origin + ",
#'         "window.location.pathname.replace(",
#'           "/\\(__swagger__\\\\/|__swagger__\\\\/index.html\\)$/, \"\"",
#'         ") + ",
#'         "\"openapi.json\""
#'       ),
#'       version = version
#'     )
#'   },
#'   static = function(version = "3", ...) {
#'     swagger::swagger_path(version)
#'   }
#' )
#'
#' # When setting the UI, `index` and `static` function arguments can be supplied
#' # * via `pr_set_ui()`
#' # * or through URL query string variables
#' pr() %>%
#'   # Set default argument `version = 3` for the swagger `index` and `static` functions
#'   pr_set_ui("swagger", version = 3) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
#' @rdname register_ui
register_ui <- function(name, index, static = NULL) {

  stopifnot(is.character(name) && length(name) == 1L)
  stopifnot(grepl("^[a-zA-Z0-9_]+$", name))
  stopifnot(is.function(index))
  if (!is.null(static)) stopifnot(is.function(static))

  ui_root <- paste0("/__", name, "__/")
  ui_paths <- c("/index.html", "/")

  mount_ui_func <- function(pr, api_url, ...) {

    # Save initial extra argument values
    args_index <- list(...)

    ui_index <- function(...) {
      # Override with arguments provided live with URI (i.e. index.html?version=2)
      args <- utils::modifyList(args_index, list(...))
      # Remove default arguments req and res
      args <- args[!(names(args) %in% c("req", "res"))]
      do.call(index, args)
    }

    ui_router <- Plumber$new()
    for (path in ui_paths) {
      ui_router$handle("GET", path, ui_index, serializer = serializer_html())
    }
    if (!is.null(static)) {
      ui_router$mount("/", PlumberStatic$new(static(...)))
    }

    if (!is.null(pr$mounts[[ui_root]])) {
      message("Overwritting existing `", ui_root, "` mount")
      message("")
    }

    pr$mount(ui_root, ui_router)

    ui_url <- paste0(api_url, ui_root)
    return(ui_url)
  }
  unmount_ui_func <- function(pr) {
    pr$unmount(ui_root)
    invisible()
  }

  if (is.null(.globals$UIs[[name]])) {
    .globals$UIs[[name]] <- list()
  }
  .globals$UIs[[name]]$mount <- mount_ui_func
  .globals$UIs[[name]]$unmount <- unmount_ui_func

  invisible(name)
}
#' @export
#' @rdname register_ui
registered_uis <- function() {
  sort(names(.globals$UIs))
}

# TODO: Remove once UI load code moved to respective UI package
swagger_ui <- list(
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
register_uis_onLoad <- function() {
  register_ui(swagger_ui$name, swagger_ui$index, swagger_ui$static)
}
