#' Set the default serializer of the router
#'
#' By default, Plumber serializes responses to JSON. This function updates the
#' default serializer to the function supplied via \code{serializer}
#'
#' @template param_pr
#' @param serializer A serializer function
#'
#' @return The Plumber router with the new default serializer
#'
#' @export
pr_set_serializer <- function(pr, serializer) {
  validate_pr(pr)
  pr$setSerializer(serializer)
  invisible(pr)
}

#' Set the default endpoint parsers for the router
#'
#' By default, Plumber will parse JSON, text, query strings, octet streams, and multipart bodies. This function updates the
#' default parsers for any endpoint that does not define their own parsers.
#'
#' Note: The default set of parsers will be completely replaced if any value is supplied. Be sure to include all of your parsers that you would like to include.
#'
#' @template param_pr
#' @template pr_set_parsers__parsers
#'
#' @return The Plumber router with the new default [PlumberEndpoint] parsers
#'
#' @export
pr_set_parsers <- function(pr, parsers) {
  validate_pr(pr)
  pr$set_parsers(parsers)
  invisible(pr)
}

#' Set the handler that is called when the incoming request can't be served
#'
#' This function allows a custom error message to be returned when a request
#' cannot be served by an existing endpoint or filter.
#'
#' @template param_pr
#' @param fun A handler function
#'
#' @return The Plumber router with a modified 404 handler
#'
#' @examples
#' \dontrun{
#' handler_404 <- function(req, res) {
#'   res$status <- 404
#'   res$body <- "Oops"
#' }
#'
#' pr() %>%
#'   pr_get("/hi", function() "Hello") %>%
#'   pr_set_404(handler_404) %>%
#'   pr_run()
#' }
#'
#' @export
pr_set_404 <- function(pr, fun) {
  validate_pr(pr)
  pr$set404Handler(fun)
  invisible(pr)
}

#' Set the error handler that is invoked if any filter or endpoint generates an
#' error
#'
#' @template param_pr
#' @param fun An error handler function. This should accept `req`, `res`, and the error value
#'
#' @return The Plumber router with a modified error handler
#'
#' @examples
#' \dontrun{
#' handler_error <- function(req, res, err){
#'   res$status <- 500
#'   list(error = "Custom Error Message")
#' }
#'
#' pr() %>%
#'   pr_get("/error", function() log("a")) %>%
#'   pr_set_error(handler_error) %>%
#'   pr_run()
#' }
#' @export
pr_set_error <- function(pr, fun) {
  validate_pr(pr)
  pr$setErrorHandler(fun)
  invisible(pr)
}




#' Set debug value to include error messages of routes cause an error
#'
#' To hide any error messages in production, set the debug value to `FALSE`.
#' The `debug` value is enabled by default for [interactive()] sessions.
#'
#' @template param_pr
#' @param debug `TRUE` provides more insight into your API errors.
#' @return The Plumber router with the new debug setting.
#' @export
#' @examples
#' \dontrun{
#' # Will contain the original error message
#' pr() %>%
#'   pr_set_debug(TRUE) %>%
#'   pr_get("/boom", function() stop("boom")) %>%
#'   pr_run()
#'
#' # Will NOT contain an error message
#' pr() %>%
#'   pr_set_debug(FALSE) %>%
#'   pr_get("/boom", function() stop("boom")) %>%
#'   pr_run()
#' }
pr_set_debug <- function(pr, debug = interactive()) {
  validate_pr(pr)
  pr$set_debug(debug = debug)
  invisible(pr)
}


#' Set the API user interface
#'
#' `ui` should be either a logical or a character value matching a registered ui.
#' When `TRUE` or a
#' function, multiple handles will be added to `plumber` object. OpenAPI json
#' file will be served on paths `/openapi.json` and `/swagger.json`. Swagger UI
#' will be served on paths `/__swagger__/index.html` and `/__swagger__/`. When
#' using a function, it will receive the Plumber router as the first parameter
#' and current OpenAPI Specification as the second. This function should return a
#' list containing OpenAPI Specification.
#' See \url{http://spec.openapis.org/oas/v3.0.3}
#'
#' @template param_pr

#' @param ui a character value or a logical value.
#' If using [options_plumber()], the value must be set before initializing your Plumber router.
#' @param ... Other params to be passed to `ui` functions.
#' @return The Plumber router with the new UI settings.
#' @export
#' @examples
#' \dontrun{
#' ## View API using Swagger UI
#' # Official Website: https://swagger.io/tools/swagger-ui/
#' # install.packages("swagger")
#' if (require(swagger)) {
#'   pr() %>%
#'     pr_set_ui("swagger") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## View API using Redoc
#' # Official Website: https://github.com/Redocly/redoc
#' # remotes::install_github("https://github.com/meztez/redoc/")
#' if (require(redoc)) {
#'   pr() %>%
#'     pr_set_ui("redoc") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## View API using RapiDoc
#' # Official Website: https://github.com/mrin9/RapiDoc
#' # remotes::install_github("https://github.com/meztez/rapidoc/")
#' if (require(rapidoc)) {
#'   pr() %>%
#'     pr_set_ui("rapidoc") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## Disable the OpenAPI Spec UI
#' pr() %>%
#'   pr_set_ui(FALSE) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
pr_set_ui <- function(
  pr,
  ui = getOption("plumber.ui", TRUE),
  ...
) {
  validate_pr(pr)
  pr$set_ui(ui = ui, ...)
  invisible(pr)
}


#' Set the `callback` to tell where the API user interface is located
#'
#' When set, it will be called with a character string corresponding
#' to the API UI url. This allows RStudio to open `swagger` UI when a
#' Plumber router [pr_run()] method.
#'
#' If using [options_plumber()], the value must be set before initializing your Plumber router.
#'
#' @template param_pr
#' @param callback a callback function for taking action on UI url.
#' @return The Plumber router with the new UI callback setting.
#' @export
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_set_ui_callback(function(url) { message("API location: ", url) }) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
pr_set_ui_callback <- function(
  pr,
  callback = getOption('plumber.ui.callback', getOption('plumber.swagger.url', NULL))
) {
  validate_pr(pr)
  pr$set_ui_callback(callback = callback)
  invisible(pr)
}


#' Set the OpenAPI Specification information
#'
#' When set, it will be called with a character string corresponding
#' to the API UI url. This allows RStudio to open `swagger` UI when a
#' Plumber router [pr_run()] method is executed using default `plumber.ui.callback` option.
#'
#' @template param_pr
#' @template pr_set_api_spec__api
#' @return The Plumber router with the new OpenAPI Specification object or function.
#' @export
#' @examples
#' \dontrun{
#' # Set the API Spec to a function to use the auto-generated OAS object
#' pr() %>%
#'   pr_set_api_spec(function(spec) {
#'     spec$info$title <- Sys.time()
#'     spec
#'   }) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#'
#' # Set the API Spec using an object
#' pr() %>%
#'   pr_set_api_spec(my_custom_object) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
pr_set_api_spec <- function(
  pr,
  api
) {
  validate_pr(pr)
  pr$set_api_spec(api = api)
  invisible(pr)
}
