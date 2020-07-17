#' Create a new Plumber router
#'
#' @param filters a list of plumber filters
#' @param file path to file to plumb
#' @param envir an environment to be used as the enclosure for the routers execution
#'
#' @return A new `plumber` router
#'
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_run()
#' }
#'
#' @export
pr <- function(file = NULL,
               filters = defaultPlumberFilters,
               envir = new.env(parent = .GlobalEnv)) {
  plumber$new(file = file, filters = filters, envir = envir)
}

#' Add handler to Plumber router
#'
#' This collection of functions creates handlers for a Plumber router.
#'
#' The generic [pr_handle()] creates a handle for the given methods. Specific
#' functions are implemented for the following HTTP methods:
#' * `GET`
#' * `POST`
#' * `PUT`
#' * `DELETE`
#' * `HEAD`
#' Each function mutates the plumber router in place, but also invisibly returns
#' the updated router.
#'
#' @param pr A plumber router
#' @param methods Character vector of HTTP methods
#' @param path The endpoint path
#' @param handler a handler function
#' @param preempt a preempt function
#' @param serializer a plumber serializer
#' @param endpoint a `PlumberEndpoint` object
#' @param ... additional arguments for `PlumberEndpoint`
#'
#' @return A plumber router with the handler added
#'
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_handle("GET", "/hi", function() "Hello World") %>%
#'   pr_run()
#'
#' pr() %>%
#'   pr_handle(c("GET", "POST"), "/hi", function() "Hello World") %>%
#'   pr_run()
#'
#' pr() %>%
#'   pr_get("/hi", function() "Hello World") %>%
#'   pr_post("/echo", function(req, res) {
#'     if (req$postBody == "") return("No input")
#'     input <- jsonlite::fromJSON(req$POST_BODY)
#'     list(
#'       input = input
#'     )
#'   }) %>%
#'   pr_run()
#' }
#'
#' @export
pr_handle <- function(pr,
                      methods,
                      path,
                      handler,
                      preempt,
                      serializer,
                      endpoint,
                      ...) {
  pr$handle(methods = methods,
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
  invisible(pr)
}

#' @rdname pr_handle
#' @export
pr_get <- function(pr,
                   path,
                   handler,
                   preempt,
                   serializer,
                   endpoint,
                   ...) {
  pr_handle(pr,
            "GET",
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
}

#' @rdname pr_handle
#' @export
pr_post <- function(pr,
                    path,
                    handler,
                    preempt,
                    serializer,
                    endpoint,
                    ...) {
  pr_handle(pr,
            "POST",
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
}

#' @rdname pr_handle
#' @export
pr_put <- function(pr,
                   path,
                   handler,
                   preempt,
                   serializer,
                   endpoint,
                   ...) {
  pr_handle(pr,
            "PUT",
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
}

#' @rdname pr_handle
#' @export
pr_delete <- function(pr,
                      path,
                      handler,
                      preempt,
                      serializer,
                      endpoint,
                      ...) {
  pr_handle(pr,
            "DELETE",
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
}

#' @rdname pr_handle
#' @export
pr_head <- function(pr,
                    path,
                    handler,
                    preempt,
                    serializer,
                    endpoint,
                    ...) {
  pr_handle(pr,
            "HEAD",
            path = path,
            handler = handler,
            preempt = preempt,
            serializer = serializer,
            endpoint = endpoint,
            ...)
}

#' Mount a plumber router
#'
#' Plumber routers can be “nested” by mounting one into another
#' using the `mount()` method. This allows you to compartmentalize your API
#' by paths which is a great technique for decomposing large APIs into smaller
#' files. This function mutates the plumber router (\code{pr}) in place, but
#' also invisibly returns the updated router.
#'
#' @param pr the host plumber router.
#' @param path a character string. Where to mount router.
#' @param router a plumber router. Router to be mounted.
#'
#' @return a plumber router with the supplied router mounted
#'
#' @examples
#' \dontrun{
#' pr1 <- pr() %>%
#'   pr_get("/hello", function() "Hello")
#'
#' pr() %>%
#'   pr_get("/goodbye", function() "Goodbye") %>%
#'   pr_mount("/hi", pr1) %>%
#'   pr_run()
#' }
#'
#' @export
pr_mount <- function(pr,
                     path,
                     router) {
  pr$mount(path = path, router = router)
  invisible(pr)
}

#' Register a hook
#'
#' Plumber routers support the notion of "hooks" that can be registered
#' to execute some code at a particular point in the lifecycle of a request.
#' Plumber routers currently support four hooks:
#'  1. `preroute(data, req, res)`
#'  2. `postroute(data, req, res, value)`
#'  3. `preserialize(data, req, res, value)`
#'  4. `postserialize(data, req, res, value)`
#' In all of the above you have access to a disposable environment in the `data`
#' parameter that is created as a temporary data store for each request. Hooks
#' can store temporary data in these hooks that can be reused by other hooks
#' processing this same request.
#'
#' One feature when defining hooks in Plumber routers is the ability to modify
#' the returned value. The convention for such hooks is: any function that accepts
#' a parameter named `value` is expected to return the new value. This could
#' be an unmodified version of the value that was passed in, or it could be a
#' mutated value. But in either case, if your hook accepts a parameter
#' named `value`, whatever your hook returns will be used as the new value
#' for the response.
#'
#' You can add hooks using the `pr_hook`, or you can add multiple
#' hooks at once using `pr_hooks`, which takes a named list in
#' which the names are the names of the hooks, and the values are the
#' handlers themselves.
#'
#' @param pr a plumber router
#' @param stage a character string. Point in the lifecycle of a request.
#' @param handler a hook function.
#' @param handlers a named list of hook handlers
#'
#' @return a plumber router with the defined hook(s) added
#'
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_hook("preroute", function(req){
#'     cat("Routing a request for", req$PATH_INFO, "...\n")
#'   }) %>%
#'   pr_hooks(list(
#'     preserialize = function(req, value){
#'       print("About to serialize this value:")
#'       print(value)
#'
#'       # Must return the value since we took one in. Here we're not choosing
#'       # to mutate it, but we could.
#'       value
#'     },
#'     postserialize = function(res){
#'       print("We serialized the value as:")
#'       print(res$body)
#'     }
#'   )) %>%
#'   pr_handle("GET", "/", function(){ 123 }) %>%
#'   pr_run()
#' }
#'
#' @export
pr_hook <- function(pr,
                    stage,
                    handler) {
  pr$registerHook(stage = stage, handler = handler)
  invisible(pr)
}

#' @rdname pr_hook
#' @export
pr_hooks <- function(pr,
                     handlers) {
  pr$registerHooks(handlers)
  invisible(pr)
}

#' Store session data in encrypted cookies.
#'
#' \code{plumber} uses the crypto R package \code{sodium}, to encrypt/decrypt
#' \code{req$session} information for each server request.
#'
#' The cookie's secret encryption \code{key} value must be consistent to maintain
#' \code{req$session} information between server restarts.
#'
#' @section Storing secure keys:
#' While it is very quick to get started with user session cookies using
#' \code{plumber}, please exercise precaution when storing secure key information.
#' If a malicious person were to gain access to the secret \code{key}, they would
#' be able to eavesdrop on all \code{req$session} information and/or tamper with
#' \code{req$session} information being processed.
#'
#' Please: \itemize{
#' \item Do NOT store keys in source control.
#' \item Do NOT store keys on disk with permissions that allow it to be accessed by everyone.
#' \item Do NOT store keys in databases which can be queried by everyone.
#' }
#'
#' Instead, please: \itemize{
#' \item Use a key management system, such as
#' \href{https://github.com/r-lib/keyring}{'keyring'} (preferred)
#' \item Store the secret in a file on disk with appropriately secure permissions,
#'   such as "user read only" (\code{Sys.chmod("myfile.txt", mode = "0600")}),
#'   to prevent others from reading it.
#' } Examples of both of these solutions are done in the Examples section.
#'
#' @param pr A plumber router
#' @param key The secret key to use. This must be consistent across all R sessions
#'   where you want to save/restore encrypted cookies. It should be produced using
#'   \code{\link{randomCookieKey}}. Please see the "Storing secure keys" section for more details
#'   complex character string to bolster security.
#' @param name The name of the cookie in the user's browser.
#' @param expiration A number representing the number of seconds into the future
#'   before the cookie expires or a \code{POSIXt} date object of when the cookie expires.
#'   Defaults to the end of the user's browser session.
#' @param http Boolean that adds the \code{HttpOnly} cookie flag that tells the browser
#'   to save the cookie and to NOT send it to client-side scripts. This mitigates \href{https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting}{cross-site scripting}.
#'   Defaults to \code{TRUE}.
#' @param secure Boolean that adds the \code{Secure} cookie flag.  This should be set
#'   when the route is eventually delivered over \href{https://en.wikipedia.org/wiki/HTTPS}{HTTPS}.
#' @seealso \itemize{
#' \item \href{https://github.com/jeroen/sodium}{'sodium'}: R bindings to 'libsodium'
#' \item \href{https://download.libsodium.org/doc/}{'libsodium'}: A Modern and Easy-to-Use Crypto Library
#' \item \href{https://github.com/r-lib/keyring}{'keyring'}: Access the system credential store from R
#' \item \href{https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie#Directives}{Set-Cookie flags}: Descriptions of different flags for \code{Set-Cookie}
#' \item \href{https://developer.mozilla.org/en-US/docs/Glossary/Cross-site_scripting}{Cross-site scripting}: A security exploit which allows an attacker to inject into a website malicious client-side code
#' }
#' @examples
#' \dontrun{
#'
#' ## Set secret key using `keyring` (preferred method)
#' keyring::key_set_with_value("plumber_api", password = plumber::randomCookieKey())
#'
#'
#' pr() %>%
#'   pr_cookie(
#'     keyring::key_get("plumber_api"),
#'     name = "counter"
#'   ) %>%
#'   pr_get("/sessionCounter", function(req) {
#'     count <- 0
#'     if (!is.null(req$session$counter)){
#'       count <- as.numeric(req$session$counter)
#'     }
#'     req$session$counter <- count + 1
#'     return(paste0("This is visit #", count))
#'   }) %>%
#'   pr_run()
#'
#'
#' #### -------------------------------- ###
#'
#'
#' ## Save key to a local file
#' pswd_file <- "normal_file.txt"
#' cat(plumber::randomCookieKey(), file = pswd_file)
#' # Make file read-only
#' Sys.chmod(pswd_file, mode = "0600")
#'
#' pr() %>%
#'   pr_cookie(
#'     readLines(pswd_file, warn = FALSE),
#'     name = "counter"
#'   ) %>%
#'   pr_get("/sessionCounter", function(req) {
#'     count <- 0
#'     if (!is.null(req$session$counter)){
#'       count <- as.numeric(req$session$counter)
#'     }
#'     req$session$counter <- count + 1
#'     return(paste0("This is visit #", count))
#'   }) %>%
#'   pr_run()
#' }
#' @export
pr_cookie <- function(pr,
                      key,
                      name = "plumber",
                      expiration = FALSE,
                      http = TRUE,
                      secure = FALSE) {
  pr$registerHooks(
    sessionCookie(key = key, name = name, expiration = expiration, http = http, secure = secure)
  )
  invisible(pr)
}

#' Set the default serializer of the router
#'
#' By default, Plumber serializes responses to JSON. This function updates the
#' default serializer to the function supplied via \code{serializer}
#'
#' @param pr A plumber router
#' @param serializer a serializer function
#'
#' @return The plumber router with the new default serializer
#'
#' @export
pr_serializer <- function(pr,
                          serializer) {
  pr$setSerializer(serializer)
  invisible(pr)
}

#' Set the handler that is called when the incoming request can't be served
#'
#' This function allows a custom error message to be returned when a request
#' cannot be served by an existing endpoint or filter.
#'
#' @param pr a plumber router
#' @param fun a handler function
#'
#' @return The plumber router with a modified 404 handler
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
#'   pr_404(handler_404) %>%
#'   pr_run()
#' }
#'
#' @export
pr_404 <- function(pr,
                   fun) {
  pr$set404Handler(fun)
  invisible(pr)
}

#' Set the error handler that is invoked if any filter or endpoint generates an
#' error
#'
#' @param pr a plumber router
#' @param fun a handler function
#'
#' @return The plumber router with a modified error handler
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
#'   pr_error(handler_error) %>%
#'   pr_run()
#' }
#' @export
pr_error <- function(pr,
                     fun) {
  pr$setErrorHandler(fun)
  invisible(pr)
}

#' Add a filter to plumber router
#'
#' Filters can be used to modify an incoming request, return an error, or return
#' a response prior to the request reaching an endpoint.
#'
#' @param pr a plumber router
#' @param name a character string. Name of filter
#' @param expr an expr that resolve to a filter function or a filter function
#' @param serializer a serializer function
#'
#' @return The plumber router with the defined filter added
#'
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_filter("foo", function(req, res) {
#'     print("This is filter foo")
#'     forward()
#'   }) %>%
#'   pr_get("/hi", function() "Hello") %>%
#'   pr_run()
#' }
#'
#' @export
pr_filter <- function(pr,
                      name,
                      expr,
                      serializer) {
  pr$filter(name = name, expr = expr, serializer = serializer)
  invisible(pr)
}

#' Start a server using `plumber` object
#'
#' `port` does not need to be explicitly assigned.
#'
#' `swagger` should be either a logical or a function . When `TRUE` or a
#' function, multiple handles will be added to `plumber` object. OpenAPI json
#' file will be served on paths `/openapi.json` and `/swagger.json`. Swagger UI
#' will be served on paths `/__swagger__/index.html` and `/__swagger__/`. When
#' using a function, it will receive the plumber router as the first parameter
#' and current OpenAPI Specification as the second. This function should return a
#' list containing OpenAPI Specification.
#' See \url{http://spec.openapis.org/oas/v3.0.3}
#'
#' `swaggerCallback` When set, it will be called with a character string corresponding
#' to the swagger UI url. It allows RStudio to open swagger UI when plumber router
#' run method is executed using default `plumber.swagger.url` option.
#'
#' @param pr A plumber router
#' @param host a string that is a valid IPv4 or IPv6 address that is owned by
#' this server, which the application will listen on. "0.0.0.0" represents
#' all IPv4 addresses and "::/0" represents all IPv6 addresses.
#' @param port a number or integer that indicates the server port that should
#' be listened on. Note that on most Unix-like systems including Linux and
#' Mac OS X, port numbers smaller than 1025 require root privileges.
#' @param swagger a function that enhances the existing OpenAPI Specification.
#' @param debug `TRUE` provides more insight into your API errors.
#' @param swaggerCallback a callback function for taking action on the url for swagger page.
#'
#' @examples
#' \dontrun{
#' pr() %>%
#'   pr_run()
#'
#' pr() %>%
#'   pr_run(port = 5762, debug = TRUE)
#' }
#'
#' @export
pr_run <- function(pr,
                   host = '127.0.0.1',
                   port = getOption('plumber.port'),
                   swagger = interactive(),
                   debug = interactive(),
                   swaggerCallback = getOption('plumber.swagger.url', NULL)
) {
  pr$run(host = host,
         port = port,
         swagger = swagger,
         debug = debug,
         swaggerCallback = swaggerCallback)
}
