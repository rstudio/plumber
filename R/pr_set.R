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
#' Use `registered_parsers()` to get a list of available parser names.
#'
#' @template param_pr
#' @template pr_setParsers__parsers
#'
#' @return The Plumber router with the new default [PlumberEndpoint] parsers
#'
#' @export
pr_set_parsers <- function(pr, parsers) {
  validate_pr(pr)
  pr$setParsers(parsers)
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
  pr$setDebug(debug = debug)
  invisible(pr)
}


#' Set the API visual documentation
#'
#' `docs` should be either a logical or a character value matching a registered visual documentation.
#' Multiple handles will be added to [`Plumber`] object. OpenAPI json
#' file will be served on paths `/openapi.json`. Documentation
#' will be served on paths `/__docs__/index.html` and `/__docs__/`.
#'
#' @template param_pr

#' @param docs a character value or a logical value.
#' If using [options_plumber()], the value must be set before initializing your Plumber router.
#' @param ... Arguments for the visual documentation. See each visual documentation package for further details.
#' @return The Plumber router with the new docs settings.
#' @export
#' @examples
#' \dontrun{
#' ## View API using Swagger UI
#' # Official Website: https://swagger.io/tools/swagger-ui/
#' # install.packages("swagger")
#' if (require(swagger)) {
#'   pr() %>%
#'     pr_set_docs("swagger") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## View API using Redoc
#' # Official Website: https://github.com/Redocly/redoc
#' # remotes::install_github("https://github.com/meztez/redoc/")
#' if (require(redoc)) {
#'   pr() %>%
#'     pr_set_docs("redoc") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## View API using RapiDoc
#' # Official Website: https://github.com/mrin9/RapiDoc
#' # remotes::install_github("https://github.com/meztez/rapidoc/")
#' if (require(rapidoc)) {
#'   pr() %>%
#'     pr_set_docs("rapidoc") %>%
#'     pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'     pr_run()
#' }
#'
#' ## Disable the OpenAPI Spec UI
#' pr() %>%
#'   pr_set_docs(FALSE) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
pr_set_docs <- function(
  pr,
  docs = getOption("plumber.docs", TRUE),
  ...
) {
  validate_pr(pr)
  pr$setDocs(docs = docs, ...)
  invisible(pr)
}


#' Set the `callback` to tell where the API visual documentation is located
#'
#' When set, it will be called with a character string corresponding
#' to the API visual documentation url. This allows RStudio to locate visual documentation.
#'
#' If using [options_plumber()], the value must be set before initializing your Plumber router.
#'
#' @template param_pr
#' @param callback a callback function for taking action on the docs url.
#' @return The Plumber router with the new docs callback setting.
#' @export
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_set_docs_callback(function(url) { message("API location: ", url) }) %>%
#'   pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
#'   pr_run()
#' }
pr_set_docs_callback <- function(
  pr,
  callback = getOption('plumber.docs.callback', NULL)
) {
  validate_pr(pr)
  pr$setDocsCallback(callback = callback)
  invisible(pr)
}


#' Set the OpenAPI Specification
#'
#' Allows to modify OpenAPI Specification autogenerated by `plumber`.
#'
#' Note, the returned value will be sent through [serializer_unboxed_json()] which will turn all length 1 vectors into atomic values.
#' To force a vector to serialize to an array of size 1, be sure to call [as.list()] on your value. `list()` objects are always serialized to an array value.
#'
#' @template param_pr
#' @template pr_setApiSpec__api
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
  pr$setApiSpec(api = api)
  invisible(pr)
}
