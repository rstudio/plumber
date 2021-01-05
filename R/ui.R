#' @include globals.R

# Mount OpenAPI and Docs
#' @noRd
mount_docs <- function(pr, host, port, docs_info, callback) {

  # return early if not enabled
  if (!isTRUE(docs_info$enabled)) {
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

  # Mount OpenAPI spec paths openapi.json
  mount_openapi(pr, api_url)

  # Mount Docs
  if (length(registered_docs()) == 0) {
    message("No visual documentation options registered. See help(register_docs).")
    return()
  }

  if (is_docs_available(docs_info$docs)) {
    docs_mount <- .globals$docs[[docs_info$docs]]$mount
    docs_url <- do.call(docs_mount, c(list(pr, api_url), docs_info$args))
    message("Running ", docs_info$docs, " Docs at ", docs_url, sep = "")
  } else {
    return()
  }

  # Use callback
  if (is.function(callback)) {
    callback(docs_url)
  }

  invisible()

}

# Check is Docs is available
#' @noRd
is_docs_available <- function(docs) {
  if (isTRUE(docs %in% registered_docs())) {
    return(TRUE)
  } else {
    message("Unknown docs \"", docs,"\". Maybe try library(", docs,").")
    return(FALSE)
  }
}

# Unmount OpenAPI and Docs
#' @noRd
unmount_docs <- function(pr, docs_info) {

  # return early if not enabled
  if (!isTRUE(docs_info$enabled)) {
    return()
  }

  # Unount OpenAPI spec paths openapi.json
  unmount_openapi(pr)

  # Mount Docs
  docs_unmount <- .globals$docs[[docs_info$docs]]$unmount
  if (length(docs_unmount) && is.function(docs_unmount)) {
    docs_unmount(pr = pr)
  }
}

#' Mount OpenAPI Specification to a plumber router
#' @noRd
mount_openapi <- function(pr, api_url) {

  spec <- pr$getApiSpec()

  # Create a function that's hardcoded to return the OpenAPI specification -- regardless of env.
  openapi_fun <- function(req) {
    # use the HTTP_REFERER so RSC can find the Docs location to ask
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
        api_url <- sub("__docs__/$", "", api_url)
      }
    }

    utils::modifyList(list(servers = list(list(url = api_url))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json"
  for (ep in pr$endpoints[["__no-preempt__"]]) {
    if (ep$path == "/openapi.json") {
      message("Overwritting existing `/openapi.json` route. Use `$setApiSpec()` to define your OpenAPI Spec")
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

#' Add visual documentation for plumber to use
#'
#' [register_docs()] is used by other packages like `swagger`, `rapidoc`, and `redoc`.
#' When you load these packages, it calls [register_docs()] to provide a user
#' interface that can interpret your plumber OpenAPI Specifications.
#'
#' @param name Name of the visual documentation
#' @param index A function that returns the HTML content of the landing page of the documentation.
#'   Parameters (besides `req` and `res`) will be supplied as if it is a regular `GET` route.
#'   Default parameter values may be used when setting the documentation `index` function.
#'   See the example below.
#' @param static A function that returns the path to the static assets (images, javascript, css, fonts) the Docs will use.
#'
#' @export
#' @examples
#' \dontrun{
#' # Example from the `swagger` R package
#' register_docs(
#'   name = "swagger",
#'   index = function(version = "3", ...) {
#'     swagger::swagger_spec(
#'       api_path = paste0(
#'         "window.location.origin + ",
#'         "window.location.pathname.replace(",
#'           "/\\(__docs__\\\\/|__docs__\\\\/index.html\\)$/, \"\"",
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
#' # When setting the docs, `index` and `static` function arguments can be supplied
#' # * via `pr_set_docs()`
#' # * or through URL query string variables
#' pr() %>%
#'   # Set default argument `version = 3` for the swagger `index` and `static` functions
#'   pr_set_docs("swagger", version = 3) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
#' @rdname register_docs
register_docs <- function(name, index, static = NULL) {

  stopifnot(is.character(name) && length(name) == 1L)
  stopifnot(grepl("^[a-zA-Z0-9_]+$", name))
  stopifnot(is.function(index))
  if (!is.null(static)) stopifnot(is.function(static))

  docs_root <- paste0("/__docs__/")
  docs_paths <- c("/index.html", "/")
  mount_docs_func <- function(pr, api_url, ...) {
    # Save initial extra argument values
    args_index <- list(...)

    docs_index <- function(...) {
      # Override with arguments provided live with URI (i.e. index.html?version=2)
      args <- utils::modifyList(args_index, list(...))
      # Remove default arguments req and res
      args <- args[!(names(args) %in% c("req", "res"))]
      do.call(index, args)
    }

    docs_router <- Plumber$new()
    for (path in docs_paths) {
      docs_router$handle("GET", path, docs_index, serializer = serializer_html())
    }
    if (!is.null(static)) {
      docs_router$mount("/", PlumberStatic$new(static(...)))
    }

    if (!is.null(pr$mounts[[docs_root]])) {
      message("Overwritting existing `", docs_root, "` mount")
      message("")
    }

    pr$mount(docs_root, docs_router)

    # add legacy swagger redirects (RStudio Connect)
    redirect_info <- swagger_redirects()
    for (path in names(redirect_info)) {
      if (router_has_route(pr, path, "GET")) {
        message("Overwriting existing GET endpoint: ", path, ". Disable by setting `options_plumber(legacyRedirects = FALSE)`")
      }
      if (router_has_route(pr, redirect_info[[path]]$route, "GET")) {
        message("Overwriting existing GET endpoint: ", redirect_info[[path]]$route, ". Disable by setting `options_plumber(legacyRedirects = FALSE)`")
      }
      pr_get(pr, path, redirect_info[[path]]$handler)
    }

    docs_url <- paste0(api_url, docs_root)
    return(docs_url)
  }
  unmount_docs_func <- function(pr) {
    pr$unmount(docs_root)

    # remove legacy swagger redirects
    redirect_info <- swagger_redirects()
    for (path in names(redirect_info)) {
      pr$removeHandle("GET", path)
    }

    invisible()
  }

  if (is.null(.globals$docs[[name]])) {
    .globals$docs[[name]] <- list()
  }
  .globals$docs[[name]]$mount <- mount_docs_func
  .globals$docs[[name]]$unmount <- unmount_docs_func

  invisible(name)
}
#' @export
#' @rdname register_docs
registered_docs <- function() {
  sort(names(.globals$docs))
}


swagger_redirects <- function() {
  if (!isTRUE(getOption("plumber.legacyRedirects", TRUE))) {
    return(list())
  }

  to_route <- function(route) {
    list(
      route = route,
      handler = function(req, res) {
        res$status <- 301 # redirect permanently
        res$setHeader("Location", route)
        res$body <- "redirecting..."
        res
      }
    )
  }
  list(
    "/__swagger__/" = to_route("../__docs__/"),
    "/__swagger__/index.html"  = to_route("../__docs__/index.html")
  )
}


register_swagger_docs_onLoad <- function() {
  tryCatch({
    do.call(register_docs, swagger::plumber_docs())
  }, error = function(e) {
    message("Could not register `swagger` docs. ", e)
    NULL
  })
}
