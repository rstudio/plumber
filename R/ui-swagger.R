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
