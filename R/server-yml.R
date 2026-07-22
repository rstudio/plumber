# `_server.yml` engine entry point. This function is intentionally not exported;
# deployment tools retrieve it from the package namespace.
launch_server <- function(settings, host = NULL, port = NULL, ...) {
  if (!is.character(settings) || length(settings) != 1L || is.na(settings)) {
    stop("`settings` must be the path to a `_server.yml` file.")
  }

  settings <- normalizePath(settings, winslash = "/", mustWork = TRUE)
  router <- plumb(dir = dirname(settings))
  router <- add_server_docs_redirect(router)

  args <- list(pr = router, ...)
  if (!is.null(host)) {
    args$host <- host
  }
  if (!is.null(port)) {
    args$port <- port
  }

  do.call(pr_run, args)
}

add_server_docs_redirect <- function(router) {
  api_path <- get_option_or_env("plumber.apiPath", "")
  api_path <- sub("/+$", "", api_path)
  root_path <- paste0(api_path, "/")

  if (router_has_route(router, root_path, "GET")) {
    return(router)
  }

  pr_get(router, root_path, function(req, res) {
    res$status <- 301
    res$setHeader("Location", "./__docs__/")
    res$body <- "redirecting..."
    res
  })
}
