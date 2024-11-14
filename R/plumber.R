#' @import R6
#' @import stringi
#' @importFrom rlang %||%
NULL

# used to identify annotation flags.
verbs <- c("GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS", "PATCH")
enumerateVerbs <- function(v) {
  if (identical(v, "use")) {
    return(verbs)
  }
  toupper(v)
}




#' @include parse-query.R
#' @include parse-body.R
#' @include parser-cookie.R
#' @include shared-secret-filter.R
defaultPlumberFilters <- list(
  queryString = queryStringFilter,
  body = bodyFilter,
  cookieParser = cookieFilter,
  sharedSecret = sharedSecretFilter
)




#' Package Plumber Router
#'
#' Routers are the core request handler in \pkg{plumber}. A router is responsible for
#' taking an incoming request, submitting it through the appropriate filters and
#' eventually to a corresponding endpoint, if one is found.
#'
#' See the [Programmatic Usage](https://www.rplumber.io/articles/programmatic-usage.html) article for additional
#' details on the methods available on this object.
#' @seealso
#'  [pr()],
#'  [pr_run()],
#'  [pr_get()], [pr_post()],
#'  [pr_mount()],
#'  [pr_hook()], [pr_hooks()], [pr_cookie()],
#'  [pr_filter()],
#'  [pr_set_api_spec()], [pr_set_docs()],
#'  [pr_set_serializer()], [pr_set_parsers()],
#'  [pr_set_404()], [pr_set_error()],
#'  [pr_set_debug()],
#'  [pr_set_docs_callback()]
#' @include hookable.R
#' @export
Plumber <- R6Class(
  "Plumber",
  inherit = Hookable,
  public = list(

    #' @description Create a new `Plumber` router
    #'
    #' See also [plumb()], [pr()]
    #' @param filters a list of Plumber filters
    #' @param file path to file to plumb
    #' @param envir an environment to be used as the enclosure for the routers execution
    #' @return A new `Plumber` router
    initialize = function(file = NULL, filters = defaultPlumberFilters, envir) {

      if (!is.null(file)){
        if (!file.exists(file)){
          stop("File does not exist: ", file)
        } else {
          inf <- file.info(file)
          if (inf$isdir){
            stop("Expecting a file but found a directory: '", file, "'.")
          }
        }
      }

      if (missing(envir)){
        private$envir <- new.env(parent=.GlobalEnv)
      } else {
        private$envir <- envir
      }

      if (is.null(filters)){
        filters <- list()
      }

      # Initialize
      self$setSerializer(serializer_json())
      # Default parsers to maintain legacy features
      self$setParsers(c("json", "form", "text", "octet", "multi"))
      self$setErrorHandler(defaultErrorHandler())
      self$set404Handler(default404Handler)
      self$setDocs(TRUE)
      private$docs_info$has_not_been_set <- TRUE # set to know if `$setDocs()` has been called before `$run()`
      private$docs_callback <- rlang::missing_arg()
      private$debug <- NULL
      self$setApiSpec(NULL)

      # Add in the initial filters
      for (fn in names(filters)){
        fil <- PlumberFilter$new(fn, filters[[fn]], private$envir, private$default_serializer, NULL, NULL)
        private$filts <- c(private$filts, fil)
      }

      if (!is.null(file)) {
        # plumb() the file in the working directory
        # The directory is also set when running the plumber object
        private$filename <- file
        old_wd <- setwd(dirname(file))
        on.exit({setwd(old_wd)}, add = TRUE)
        file <- basename(file)

        private$lines <- readUTF8(file)
        private$parsed <- parseUTF8(file)
        private$disable_run <- TRUE
        on.exit({
          private$disable_run <- FALSE
        }, add = TRUE)

        for (i in seq_len(length(private$parsed))) {
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]]

          evaluateBlock(srcref, private$lines, e, private$envir, private$addEndpointInternal,
                        private$addFilterInternal, self)
        }

        private$globalSettings <- plumbGlobals(private$lines, private$envir)
      }

    },
    #' @description Start a server using `Plumber` object.
    #'
    #' See also: [pr_run()]
    #' @param host a string that is a valid IPv4 or IPv6 address that is owned by
    #' this server, which the application will listen on. "0.0.0.0" represents
    #' all IPv4 addresses and "::/0" represents all IPv6 addresses.
    #' @param port a number or integer that indicates the server port that should
    #' be listened on. Note that on most Unix-like systems including Linux and
    #' Mac OS X, port numbers smaller than 1025 require root privileges.
    #'
    #' This value does not need to be explicitly assigned. To explicitly set it, see [options_plumber()].
    #' @param debug If `TRUE`, it will provide more insight into your API errors. Using this value will only last for the duration of the run. If a `$setDebug()` has not been called, `debug` will default to `interactive()` at `$run()` time. See `$setDebug()` for more details.
    #' @param swagger Deprecated. Please use `docs` instead. See `$setDocs(docs)` or `$setApiSpec()` for more customization.
    #' @param swaggerCallback An optional single-argument function that is
    #'   called back with the URL to an OpenAPI user interface when one becomes
    #'   ready. If missing, defaults to information previously set with `$setDocsCallback()`.
    #'   This value will only be used while running the router.
    #' @param docs Visual documentation value to use while running the API.
    #'   This value will only be used while running the router.
    #'   If missing, defaults to information previously set with `setDocs()`.
    #'   For more customization, see `$setDocs()` or [pr_set_docs()] for examples.
    #' @param quiet If `TRUE`, don't print routine startup messages.
    #' @param ... Should be empty.
    #' @importFrom lifecycle deprecated
    #' @importFrom rlang missing_arg
    run = function(
      host = '127.0.0.1',
      port = get_option_or_env('plumber.port', NULL),
      swagger = deprecated(),
      debug = missing_arg(),
      swaggerCallback = missing_arg(),
      ...,
      # any new args should go below `...`
      docs = missing_arg(),
      quiet = FALSE
    ) {

      if (isTRUE(private$disable_run)) {
        stop("Plumber router `$run()` method should not be called while `plumb()`ing a file")
      }

      rlang::check_dots_empty()

      # Legacy support for RStudio pro products.
      # Checks must be kept for >= 2 yrs after plumber v1.0.0 release date
      if (lifecycle::is_present(swagger)) {
        if (!rlang::is_missing(docs)) {
          lifecycle::deprecate_warn("1.0.0", "Plumber$run(swagger = )", "Plumber$run(docs = )", details = "`docs` will take preference (ignoring `swagger`)")
          # (`docs` is resolved after `swagger` checks)
        } else {
          if (is.function(swagger)) {
            # between v0.4.6 and v1.0.0
            lifecycle::deprecate_warn("1.0.0", "Plumber$run(swagger = )", "Plumber$setApiSpec(api = )")
            # set the new api function and force turn on the docs
            old_api_spec_handler <- private$api_spec_handler
            self$setApiSpec(swagger)
            on.exit({
              private$api_spec_handler <- old_api_spec_handler
            }, add = TRUE)
            docs <- TRUE
          } else {
            if (isTRUE(private$docs_info$has_not_been_set)) {
              # <= v0.4.6
              lifecycle::deprecate_warn("1.0.0", "Plumber$run(swagger = )", "Plumber$run(docs = )")
              docs <- swagger
            } else {
              # $setDocs() has been called (other than during initialization).
              # `docs` is not provided
              # Believe that prior `$setDocs()` behavior is the correct behavior
              # Warn about updating the run method
              lifecycle::deprecate_warn("1.0.0", "Plumber$run(swagger = )", "Plumber$run(docs = )", details = "The Plumber docs have already been set. Ignoring `swagger` parameter.")
            }
          }
        }
      }

      port <- findPort(port)

      # Delay setting max size option. It could be set in `plumber.R`, which is after initialization
      private$maxSize <- get_option_or_env('plumber.maxRequestSize', 0) #0  Unlimited

      # Delay the setting of swaggerCallback as long as possible.
      # An option could be set in `plumber.R`, which is after initialization
      # Order: Run method parameter, internally set value, option, fallback option, NULL
      swaggerCallback <-
        rlang::maybe_missing(swaggerCallback,
          rlang::maybe_missing(private$docs_callback,
            get_option_or_env('plumber.docs.callback', get_option_or_env('plumber.swagger.url', NULL))
          )
        )

      # Delay the setting of debug as long as possible.
      # The router could be made in an interactive setting and used in background process.
      # Do not determine if interactive until run time
      prev_debug <- private$debug
      on.exit({
        private$debug <- prev_debug
      }, add = TRUE)
      # Fix the debug value while running.
      self$setDebug(
        # Order: Run method param, internally set value, is interactive()
        # `$getDebug()` is dynamic given `setDebug()` has never been called.
        rlang::maybe_missing(debug, self$getDebug())
      )

      docs_info <-
        if (!rlang::is_missing(docs)) {
          # Manually provided. Need to upgrade the parameter
          upgrade_docs_parameter(docs)
        } else {
          private$docs_info
        }

      if (!isTRUE(quiet)) {
        message("Running plumber API at ", urlHost(host = host, port = port, changeHostLocation = FALSE))
      }

      # Set and restore the wd to make it appear that the proc is running local to the file's definition.
      if (!is.null(private$filename)) {
        old_wd <- setwd(dirname(private$filename))
        on.exit({setwd(old_wd)}, add = TRUE)
      }

      if (isTRUE(docs_info$enabled)) {
        mount_docs(
          pr = self,
          host = host,
          port = port,
          docs_info = docs_info,
          callback = swaggerCallback,
          quiet = quiet
        )
        on.exit(unmount_docs(self, docs_info), add = TRUE)
      }

      on.exit(private$runHooks("exit"), add = TRUE)

      httpuv::runServer(host, port, self)
    },
    #' @description Mount a Plumber router
    #'
    #' Plumber routers can be “nested” by mounting one into another
    #' using the `mount()` method. This allows you to compartmentalize your API
    #' by paths which is a great technique for decomposing large APIs into smaller files.
    #'
    #' See also: [pr_mount()]
    #' @param path a character string. Where to mount router.
    #' @param router a Plumber router. Router to be mounted.
    #' @examples
    #' \dontrun{
    #' root <- pr()
    #'
    #' users <- Plumber$new("users.R")
    #' root$mount("/users", users)
    #'
    #' products <- Plumber$new("products.R")
    #' root$mount("/products", products)
    #' }
    mount = function(path, router) {
      # Ensure that the path has both a leading and trailing slash.
      if (!grepl("^/", path)) {
        path <- paste0("/", path)
      }
      if (!grepl("/$", path)) {
        path <- paste0(path, "/")
      }

      private$mnts[[path]] <- router
    },
    #' @description Unmount a Plumber router
    #' @param path a character string. Where to unmount router.
    unmount = function(path) {
      # Ensure that the path has both a leading and trailing slash.
      if (!grepl("^/", path)) {
        path <- paste0("/", path)
      }
      if (!grepl("/$", path)) {
        path <- paste0(path, "/")
      }
      private$mnts[[path]] <- NULL
    },
    #' @param stage a character string. Point in the lifecycle of a request.
    #' @param handler a hook function.
    #' @description Register a hook
    #'
    #' Plumber routers support the notion of "hooks" that can be registered
    #' to execute some code at a particular point in the lifecycle of a request.
    #' Plumber routers currently support four hooks:
    #' \enumerate{
    #'  \item `preroute(data, req, res)`
    #'  \item `postroute(data, req, res, value)`
    #'  \item `preserialize(data, req, res, value)`
    #'  \item `postserialize(data, req, res, value)`
    #' }
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
    #' You can add hooks using the `registerHook` method, or you can add multiple
    #' hooks at once using the `registerHooks` method which takes a name list in
    #' which the names are the names of the hooks, and the values are the
    #' handlers themselves.
    #'
    #' See also: [pr_hook()], [pr_hooks()]
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$registerHook("preroute", function(req){
    #'   cat("Routing a request for", req$PATH_INFO, "...\n")
    #' })
    #' pr$registerHooks(list(
    #'   preserialize=function(req, value){
    #'     print("About to serialize this value:")
    #'     print(value)
    #'
    #'     # Must return the value since we took one in. Here we're not choosing
    #'     # to mutate it, but we could.
    #'     value
    #'   },
    #'   postserialize=function(res){
    #'     print("We serialized the value as:")
    #'     print(res$body)
    #'   }
    #' ))
    #'
    #' pr$handle("GET", "/", function(){ 123 })
    #' }
    registerHook = function(stage=c("preroute", "postroute",
                                    "preserialize", "postserialize", "exit"), handler){
      stage <- match.arg(stage)
      super$registerHook(stage, handler)
    },
    #' @description Define endpoints
    #'
    #' The “handler” functions that you define in these handle calls
    #' are identical to the code you would have defined in your plumber.R file
    #' if you were using annotations to define your API. The handle() method
    #' takes additional arguments that allow you to control nuanced behavior
    #' of the endpoint like which filter it might preempt or which serializer
    #' it should use.
    #'
    #' See also: [pr_handle()], [pr_get()], [pr_post()], [pr_put()], [pr_delete()]
    #' @param methods a character string. http method.
    #' @param path a character string. Api endpoints
    #' @param handler a handler function.
    #' @param preempt a preempt function.
    #' @param serializer a serializer function.
    #' @param parsers a named list of parsers.
    #' @param endpoint a `PlumberEndpoint` object.
    #' @param ... additional arguments for [PlumberEndpoint] `new` method (namely `lines`, `params`, `comments`, `responses` and `tags`. Excludes `envir`).
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$handle("GET", "/", function(){
    #'   "<html><h1>Programmatic Plumber!</h1></html>"
    #' }, serializer=plumber::serializer_html())
    #' }
    handle = function(methods, path, handler, preempt, serializer, parsers, endpoint, ...) {
      epdef <- !missing(methods) || !missing(path) || !missing(handler) || !missing(serializer) || !missing(parsers)
      if (!missing(endpoint) && epdef) {
        stop("You must provide either the components for an endpoint (handler and serializer) OR provide the endpoint yourself. You cannot do both.")
      }

      if (epdef) {
        if (missing(serializer)) {
          serializer <- private$default_serializer
        }
        if (missing(parsers)) {
          parsers <- private$parsers
        }
        forbid <- c("verbs", "expr", "envir")
        forbid_check <- forbid %in% names(list(...))
        if (any(forbid_check)) {
          stop(paste0("`", forbid[forbid_check], "`", collapse = ", "), " can not be supplied to `pr$handle()` method.")
        }

        endpoint <- PlumberEndpoint$new(verbs = methods,
                                        path = path,
                                        expr = handler,
                                        envir = private$envir,
                                        serializer = serializer,
                                        parsers = parsers, ...)
      }
      private$addEndpointInternal(endpoint, preempt)
    },
    #' @description Remove endpoints
    #' @param methods a character string. http method.
    #' @param path a character string. Api endpoints
    #' @param preempt a preempt function.
    removeHandle = function(methods, path, preempt = NULL){
      private$removeEndpointInternal(methods, path, preempt)
    },
    #' @description Print representation of plumber router.
    #' @param prefix a character string. Prefix to append to representation.
    #' @param topLevel a logical value. When method executed on top level
    #' router, set to `TRUE`.
    #' @param ... additional arguments for recursive calls
    #' @return A terminal friendly representation of a plumber router.
    print = function(prefix="", topLevel=TRUE, ...){
      endCount <- as.character(sum(unlist(lapply(self$endpoints, length))))

      # Reference on box characters: https://en.wikipedia.org/wiki/Box-drawing_character

      cat(prefix)
      if (!topLevel){
        cat("\u2502 ") # "| "
      }

      # Avoid printing recursion (mount on mount on mount on ...)
      if (!isTRUE(topLevel)) {
        if (isTRUE(self$flags$is_printing)) {
          cat(
            crayon::bgYellow(
              crayon::black(
                "# Circular Plumber router definition detected")),
            "\n", sep=""
          )
          return()
        }
        # set flags to avoid inf recursion
        on.exit({ self$flags$is_printing <- NULL }, add = TRUE)
        self$flags$is_printing <- TRUE
      }

      cat(crayon::silver("# Plumber router with ", endCount, " endpoint", ifelse(endCount == 1, "", "s"),", ",
                         as.character(length(private$filts)), " filter", ifelse(length(private$filts) == 1, "", "s"),", and ",
                         as.character(length(self$mounts)), " sub-router", ifelse(length(self$mounts) == 1, "", "s"),".\n", sep=""))

      if(topLevel){
        cat(prefix, crayon::silver("# Use `pr_run()` on this object to start the API.\n"), sep="")
      }

      # Filters
      # TODO: scrub internal filters?
      for (f in private$filts){
        cat(prefix, "\u251c\u2500\u2500", crayon::green("[", f$name, "]", sep=""), "\n", sep="") # "+--"
      }

      printEndpoints <- function(prefix, name, nodes, isLast){
        if (is.list(nodes)){
          verbs <- paste(sapply(nodes, function(n){ n$verbs }), collapse=", ")
        } else {
          verbs <- nodes$verbs
        }
        cat(prefix)
        if (isLast){
          cat("\u2514") # "|_"
        } else {
          cat("\u251c")  # "+"
        }
        cat(crayon::blue("\u2500\u2500/", name, " (", verbs, ")\n", sep=""), sep="") # "+--"
      }

      printNode <- function(node, name="", prefix="", isRoot=FALSE, isLast = FALSE){

        childPref <- paste0(prefix, "\u2502  ")
        if (isRoot){
          childPref <- prefix
        }

        if (inherits(node, "PlumberEndpoint")) {
          # base case
          printEndpoints(prefix, name, node, isLast)

        } else if (is_plumber(node)){
          # base case
          cat(prefix, "\u251c\u2500\u2500/", name, "\n", sep="") # "+--"
          # It's a router, let it print itself
          print(node, prefix=childPref, topLevel=FALSE)

        } else if (is.list(node)) {

          has_no_name <-
            if (is.null(names(node))) {
              TRUE
            } else {
              # there are other endpoints, so get only nodes with name ""
              # which path does not end with / and path is not root
              node_path <- function(node) {
                path <- node$path %||% ""
                if (!is.character(path)) path <-""
                path
              }
              names(node) == "" & !grepl(".+/$", vapply(node, node_path, character(1)))
            }

          # mounted routers at root location will also have a missing name.
          # only look for endpoints
          are_endpoints <- has_no_name & vapply(node, inherits, logical(1), "PlumberEndpoint")
          # print all endpoints in a single line with verbs attached together
          if (any(are_endpoints)) {
            printEndpoints(prefix, name, node[are_endpoints], isLast)
          }

          # recurse
          if (any(!are_endpoints)) {
            node <- node[!are_endpoints]
            if (!isRoot){
              cat(prefix, "\u251c\u2500\u2500/", name, "\n", sep="") # "+--"
            }
            for (i in seq_along(node)) {
              name <- names(node)[i]
              printNode(node[[i]], name, childPref, isLast = (i == length(node)))
            }
          }

        } else {
          cat("??")
        }
      }
      printNode(self$routes, "", prefix, TRUE)

      invisible(self) # actually needs to be invisible
    },
    #' @description Serve a request
    #' @param req request object
    #' @param res response object
    serve = function(req, res) {
      hookEnv <- new.env()

      prerouteStep <- function(...) {
        private$runHooks("preroute", list(data = hookEnv, req = req, res = res))
      }
      routeStep <- function(...) {
        self$route(req, res)
      }
      postrouteStep <- function(value, ...) {
        private$runHooks("postroute", list(data = hookEnv, req = req, res = res, value = value))
      }

      serializeSteps <- function(value, ...) {
        if ("PlumberResponse" %in% class(value)) {
          return(res$toResponse())
        }

        ser <- res$serializer
        if (typeof(ser) != "closure") {
          stop("Serializers must be closures: '", ser, "'")
        }

        preserializeStep <- function(value, ...) {
          private$runHooks("preserialize", list(data = hookEnv, req = req, res = res, value = value))
        }
        serializeStep <- function(value, ...) {
          ser(value, req, res, private$errorHandler)
        }
        postserializeStep <- function(value, ...) {
          private$runHooks("postserialize", list(data = hookEnv, req = req, res = res, value = value))
        }

        runSteps(
          value,
          stop,
          list(
            preserializeStep,
            serializeStep,
            postserializeStep
          )
        )
      }

      errorHandlerStep <- function(error, ...) {
        # must set the body and return as this is after the serialize step
        res$body <- private$errorHandler(req, res, error)
        return(res$toResponse())
      }

      runSteps(
        NULL,
        errorHandlerStep,
        list(
          prerouteStep,
          routeStep,
          postrouteStep,
          serializeSteps
        )
      )

      #
      # conclude <- function(v) {
      #   v <- private$runHooks("postroute", list(data=hookEnv, req=req, res=res, value=v))
      #
      #   if ("PlumberResponse" %in% class(v)){
      #     # They returned the response directly, don't serialize.
      #     res$toResponse()
      #   } else {
      #     ser <- res$serializer
      #
      #     if (typeof(ser) != "closure") {
      #       stop("Serializers must be closures: '", ser, "'")
      #     }
      #
      #     v <- private$runHooks("preserialize", list(data=hookEnv, req=req, res=res, value=v))
      #     out <- ser(v, req, res, private$errorHandler)
      #     out <- private$runHooks("postserialize", list(data=hookEnv, req=req, res=res, value=out))
      #     out
      #   }
      # }
      #
      # if (hasPromises() && promises::is.promise(val)){
      #   # The endpoint returned a promise, we should wait on it
      #   then(val, conclude, function(error){
      #     # The original error handler would not have run because the endpoint didn't
      #     # synchronously produce any errors. We have to run our error handling logic now.
      #     # TODO: Dry this up with the error handler in route()
      #     v <- private$errorHandler(req, res, error)
      #     conclude(v)
      #   })
      # } else {
      #   conclude(val)
      # }
    },
    #' @description Route a request
    #' @param req request object
    #' @param res response object
    route = function(req, res) {
      getHandle <- function(filt) {
        handlers <- private$ends[[filt]]
        if (!is.null(handlers)) {
          for (h in handlers) {
            if (h$canServe(req)) {
              return(h)
            }
          }
        }
        return(NULL)
      }

      makeHandleStep <- function(name) {
        function(...) {
          resetForward()
          h <- getHandle(name)
          if (is.null(h)) {
            return(forward())
          }
          if (!is.null(h$serializer)) {
            res$serializer <- h$serializer
          }
          parsers <-
            if (!is.null(h$parsers)) {
              h$parsers
            } else {
              private$default_parsers
            }
          req$argsPath <- h$getPathParams(req$PATH_INFO)
          # `req_body_parser()` will also set `req$body` with the untouched body value
          req$body <- req_body_parser(req, parsers)
          req$argsBody <- req_body_args(req)

          req$args <- c(
            # (does not contain req or res)
            # will contain all args added in filters
            # `req$argsQuery` is available, but already absorbed into `req$args`
            req$args,
            # path is more important than body
            req$argsPath,
            # body is added last
            req$argsBody
          )

          return(
            h$exec(req, res)
          )
        }
      }

      steps <- list(
        # first step
        makeHandleStep("__first__")
      )

      # Start running through filters until we find a matching endpoint.
      # returns 2 functions which need to be flattened overall
      filterSteps <- unlist(recursive = FALSE, lapply(private$filts, function(fi) {
        # Check for endpoints preempting in this filter.
        handleStep <- makeHandleStep(fi$name)

        # Execute this filter
        # Do not stop if the filter returned a non-forward object
        # If a non-forward object is returned, serialize it according to the filter
        filterStep <- function(...) {

          filterExecStep <- function(...) {
            resetForward()
            fi$exec(req, res)
          }
          postFilterStep <- function(fres, ...) {
            if (hasForwarded()) {
              # return like normal
              return(fres)
            }
            # forward() wasn't called, presumably meaning the request was
            # handled inside of this filter.
            if (!is.null(fi$serializer)) {
              res$serializer <- fi$serializer
            }
            return(fres)
          }

          runSteps(
            NULL,
            stop,
            list(
              filterExecStep,
              postFilterStep
            )
          )
        }

        list(
          handleStep,
          filterStep
        )
      }))
      steps <- append(steps, filterSteps)

      # If we still haven't found a match, check the un-preempt'd endpoints.
      steps <- append(steps, list(makeHandleStep("__no-preempt__")))

      # We aren't going to serve this endpoint; see if any mounted routers will
      mountSteps <- lapply(names(private$mnts), function(mountPath) {
        # (make step function)
        function(...) {
          resetForward()
          # TODO: support globbing?

          if (nchar(req$PATH_INFO) >= nchar(mountPath) && substr(req$PATH_INFO, 0, nchar(mountPath)) == mountPath) {
            # This is a prefix match or exact match. Let this router handle.

            # First trim the prefix off of the PATH_INFO element
            req$PATH_INFO <- substr(req$PATH_INFO, nchar(mountPath), nchar(req$PATH_INFO))
            return(private$mnts[[mountPath]]$route(req, res))
          } else {
            return(forward())
          }
        }
      })
      steps <- append(steps, mountSteps)

      # No endpoint could handle this request. 404
      notFoundStep <- function(...) {

        if (isTRUE(get_option_or_env("plumber.trailingSlash", FALSE))) {
          # Redirect to the slash route, if it exists
          path <- req$PATH_INFO
          # If the path does not end in a slash,
          if (!grepl("/$", path)) {
            new_path <- paste0(path, "/")
            # and a route with a slash exists...
            if (router_has_route(req$pr, new_path, req$REQUEST_METHOD)) {

              # Temp redirect with same REQUEST_METHOD
              # Add on the query string manually. They do not auto transfer
              # The POST body will be reissued by caller
              new_location <- paste0(new_path, req$QUERY_STRING)
              res$status <- 307
              res$setHeader(
                name = "Location",
                value = new_location
              )
              res$serializer <- serializer_unboxed_json()
              return(
                list(message = "307 - Redirecting with trailing slash")
              )
            }
          }
        }

        # No trailing-slash route exists...
        # Try allowed verbs

        if (isTRUE(get_option_or_env("plumber.methodNotAllowed", TRUE))) {
          # Notify about allowed verbs
          if (is_405(req$pr, req$PATH_INFO, req$REQUEST_METHOD)) {
            res$status <- 405L
            # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Allow
            res$setHeader("Allow", paste(req$verbsAllowed, collapse = ", "))
            res$serializer <- serializer_unboxed_json()
            return(list(error = "405 - Method Not Allowed"))
          }
        }

        # Notify that there is no route found
        private$notFoundHandler(req = req, res = res)
      }
      steps <- append(steps, list(notFoundStep))

      errorHandlerStep <- function(error, ...) {
        private$errorHandler(req, res, error)
      }

      withCurrentExecDomain(req, res, { # used to allow `hasForwarded` to work
        withWarn1({
          runStepsIfForwarding(NULL, errorHandlerStep, steps)
        })
      })
    },
    #' @description \pkg{httpuv} interface call function. (Required for \pkg{httpuv})
    #' @param req request object
    call = function(req) {
      # Set the arguments to an empty list
      req$pr <- self
      req$.internal <- new.env()

      res <- PlumberResponse$new(private$default_serializer)
      req$args <- list()

      # maybe return a promise object
      self$serve(req, res)
    },
    #' @description httpuv interface onHeaders function. (Required for \pkg{httpuv})
    #' @param req request object
    onHeaders = function(req) {
      maxSize <- private$maxSize
      if (isTRUE(maxSize <= 0))
        return(NULL)

      reqSize <- 0
      # https://github.com/rstudio/shiny/blob/a022a2b4/R/middleware.R#L298-L301
      if (length(req$CONTENT_LENGTH) > 0)
        reqSize <- as.numeric(req$CONTENT_LENGTH)
      else if (length(req$HTTP_TRANSFER_ENCODING) > 0)
        reqSize <- Inf

      if (isTRUE(reqSize > maxSize)) {
        return(list(status = 413L,
                    headers = list('Content-Type' = 'text/plain'),
                    body = 'Maximum upload size exceeded'))
      }
      else {
        return(NULL)
      }
    },
    #' @description httpuv interface onWSOpen function. (Required for \pkg{httpuv})
    #' @param ws WebSocket object
    onWSOpen = function(ws){
      warning("WebSockets not supported.")
    },
    #' @description Sets the default serializer of the router.
    #'
    #' See also: [pr_set_serializer()]
    #' @param serializer a serializer function
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$setSerializer(serializer_unboxed_json())
    #' }
    setSerializer = function(serializer) {
      private$default_serializer <- serializer
    },
    #' @description Sets the default parsers of the router. Initialized to `c("json", "form", "text", "octet", "multi")`
    #' @template pr_setParsers__parsers
    setParsers = function(parsers) {
      private$default_parsers <- make_parser(parsers)
    },
    #' @description Sets the handler that gets called if an
    #' incoming request can’t be served by any filter, endpoint, or sub-router.
    #'
    #' See also: [pr_set_404()]
    #' @param fun a handler function.
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$set404Handler(function(req, res) {cat(req$PATH_INFO)})
    #' }
    set404Handler = function(fun){
      private$notFoundHandler <- fun
    },
    #' @description Sets the error handler which gets invoked if any filter or
    #' endpoint generates an error.
    #'
    #' See also: [pr_set_404()]
    #' @param fun a handler function.
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$setErrorHandler(function(req, res, err) {
    #'   message("Found error: ")
    #'   str(err)
    #' })
    #' }
    setErrorHandler = function(fun){
      private$errorHandler <- fun
    },
    #' @description Set visual documentation to use for API
    #'
    #' See also: [pr_set_docs()], [register_docs()], [registered_docs()]
    #' @param docs a character value or a logical value. See [pr_set_docs()] for examples.
    #'  If using [options_plumber()], the value must be set before initializing your Plumber router.
    #' @param ... Arguments for the visual documentation. See each visual documentation package for further details.
    setDocs = function(
      docs = get_option_or_env("plumber.docs", TRUE),
      ...
    ) {
      private$docs_info <- upgrade_docs_parameter(docs, ...)
    },
    #' @description Set a callback to notify where the API's visual documentation is located.
    #'
    #' When set, it will be called with a character string corresponding
    #' to the API docs url. This allows RStudio to locate visual documentation.
    #'
    #' If using [options_plumber()], the value must be set before initializing your Plumber router.
    #'
    #' See also: [pr_set_docs_callback()]
    #' @param callback a callback function for taking action on the docs url. (Also accepts `NULL` values to disable the `callback`.)
    setDocsCallback = function(
      callback = get_option_or_env('plumber.docs.callback', NULL)
    ) {
      # Use callback when defined
      if (!length(callback) || !is.function(callback)) {
        callback <- function(...) { NULL }
      }
      if (length(formals(callback)) == 0) {
        stop("`callback` must accept at least 1 argument. (`api_url`)")
      }
      private$docs_callback <- callback
    },
    #' @description Set debug value to include error messages.
    #'
    #' See also: `$getDebug()` and [pr_set_debug()]
    #' @param debug `TRUE` provides more insight into your API errors.
    setDebug = function(debug = interactive()) {
      stopifnot(length(debug) == 1)
      private$debug <- isTRUE(debug)
    },
    #' @description Retrieve the `debug` value. If it has never been set, the result of `interactive()` will be used.
    #'
    #' See also: `$getDebug()` and [pr_set_debug()]
    getDebug = function() {
      private$debug %||% default_debug()
    },
    #' @description Add a filter to plumber router
    #'
    #' See also: [pr_filter()]
    #' @param name a character string. Name of filter
    #' @param expr an expr that resolve to a filter function or a filter function
    #' @param serializer a serializer function
    filter = function(name, expr, serializer){
      filter <- PlumberFilter$new(name, expr, private$envir, serializer)
      private$addFilterInternal(filter)
    },
    #' @description
    #' Allows to modify router autogenerated OpenAPI Specification
    #'
    #' Note, the returned value will be sent through [serializer_unboxed_json()] which will turn all length 1 vectors into atomic values.
    #' To force a vector to serialize to an array of size 1, be sure to call [as.list()] on your value. `list()` objects are always serialized to an array value.
    #'
    #' See also: [pr_set_api_spec()]
    #' @template pr_setApiSpec__api
    setApiSpec = function(api = NULL) {
      if (is.character(api) && length(api) == 1 && file.exists(api)) {
        if (tools::file_ext(api) %in% c("yaml", "yml")) {
          if (!requireNamespace("yaml", quietly = TRUE)) {
            stop("yaml must be installed to read yaml format")
          }
          api <- yaml::read_yaml(api, eval.expr = FALSE)
        } else {
          api <- jsonlite::read_json(api, simplifyVector = TRUE)
        }
      }
      api_fun <-
        if (is.null(api)) {
          identity
        } else {
          if (!is.function(api)) {
            # function to return the api object
            function(x) {
              api
            }
          } else {
            api
          }
        }
      private$api_spec_handler <- api_fun
    },
    #' @description Retrieve OpenAPI file
    getApiSpec = function() { #FIXME: test

      routerSpec <- private$routerSpecificationInternal(self)

      # Extend the previously parsed settings with the endpoints
      def <- utils::modifyList(private$globalSettings, list(paths = routerSpec))

      # Lay those over the default globals so we ensure that the required fields
      # (like API version) are satisfied.
      ret <- utils::modifyList(defaultGlobals, def)

      ret <- private$api_spec_handler(ret)

      # remove NA or NULL values, which OpenAPI parsers do not like
      ret <- removeNaOrNulls(ret)

      ret
    },

    # list of key/value pairs that should be temporarily set. Ex: is_printing = 1
    #' @field flags For internal use only
    flags = list(),


    ### Legacy/Deprecated
    #' @description addEndpoint has been deprecated in v0.4.0 and will be removed in a coming release. Please use `handle()` instead.
    #' @param verbs verbs
    #' @param path path
    #' @param expr expr
    #' @param serializer serializer
    #' @param processors processors
    #' @param preempt preempt
    #' @param params params
    #' @param comments comments
    addEndpoint = function(verbs, path, expr, serializer, processors, preempt=NULL, params=NULL, comments){
      warning("addEndpoint has been deprecated in v0.4.0 and will be removed in a coming release. Please use `handle()` instead.")
      if (!missing(processors) || !missing(params) || !missing(comments)){
        stop("The processors, params, and comments parameters are no longer supported.")
      }

      self$handle(verbs, path, expr, preempt, serializer)
    },
    #' @description addAssets has been deprecated in v0.4.0 and will be removed in a coming release. Please use `mount` and `PlumberStatic$new()` instead.
    #' @param dir dir
    #' @param path path
    #' @param options options
    addAssets = function(dir, path="/public", options=list()){
      warning("addAssets has been deprecated in v0.4.0 and will be removed in a coming release. Please use `mount` and `PlumberStatic$new()` instead.")
      if (substr(path, 1,1) != "/"){
        path <- paste0("/", path)
      }

      stat <- PlumberStatic$new(dir, options)
      self$mount(path, stat)
    },
    #' @description `$addFilter()` has been deprecated in v0.4.0 and will be removed in a coming release. Please use `$filter()` instead.
    #' @param name name
    #' @param expr expr
    #' @param serializer serializer
    #' @param processors processors
    addFilter = function(name, expr, serializer, processors){
      warning("addFilter has been deprecated in v0.4.0 and will be removed in a coming release. Please use `filter` instead.")
      if (!missing(processors)){
        stop("The processors parameter is no longer supported.")
      }

      filter <- PlumberFilter$new(name, expr, private$envir, serializer)
      private$addFilterInternal(filter)
    },
    #' @description `$addGlobalProcessor()` has been deprecated in v0.4.0 and will be removed in a coming release. Please use `$registerHook`(s) instead.
    #' @param proc proc
    addGlobalProcessor = function(proc){
      warning("addGlobalProcessor has been deprecated in v0.4.0 and will be removed in a coming release. Please use `registerHook`(s) instead.")
      self$registerHooks(proc)
    },
    #' @description Deprecated. Retrieve OpenAPI file
    openAPIFile = function() {
      warning("`$openAPIFile()` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$getApiSpec()`.")
      self$getApiSpec()
    },
    #' @description Deprecated. Retrieve OpenAPI file
    swaggerFile = function() {
      warning("`$swaggerFile()` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$getApiSpec()`.")
      self$getApiSpec()
    }
  ), active = list(
    #' @field endpoints Plumber router endpoints read-only
    endpoints = function(){
      private$ends
    },
    #' @field filters Plumber router filters read-only
    filters = function(){
      private$filts
    },
    #' @field mounts Plumber router mounts read-only
    mounts = function(){
      private$mnts
    },
    #' @field environment Plumber router environment read-only
    environment = function() {
      private$envir
    },
    #' @field routes Plumber router routes read-only
    routes = function(){
      paths <- list()

      addPath <- function(node, children, endpoint){
        if (length(children) == 0){
          if (is.null(node)){
            return(endpoint)
          } else {
            # Concat to existing.
            return(c(node, endpoint))
          }

        }
        if (is.null(node)){
          node <- list()
        }

        # Check for existing endpoints at current children node that share the same name
        matching_name_nodes <- node[names(node) == children[1]]
        existing_endpoints <- vapply(matching_name_nodes, inherits, logical(1), "PlumberEndpoint")

        # This is for situation where an endpoint is on `/A` and you
        # also have route with an endpoint on `A/B`. Resulting nested list
        # already has an endpoint on the children node and you need a deeper nested
        # list for the current children node. Combine them.
        if (any(existing_endpoints) && length(children) > 1) {
          node <- c(
            # Nodes with preexisting endpoints sharing the same name
            matching_name_nodes[existing_endpoints],
            # New nested list to combine with, passing the nodes that are not endpoints
            addPath(matching_name_nodes[!existing_endpoints], children, endpoint)
          )
        } else {
          # Keep building the nested list until you hit an endpoint
          node[[children[1]]] <- addPath(node[[children[1]]], children[-1], endpoint)
        }

        node
      }

      lapply(self$endpoints, function(ends){
        lapply(ends, function(e){
          # Trim leading slash
          path <- sub("^/", "", e$path)

          levels <- strsplit(path, "/", fixed=TRUE)[[1]]
          # If there is a trailing `/`, add a blank level for an extra print line
          if (grepl("/$", path)) {levels <- c(levels, "")}
          paths <<- addPath(paths, levels, e)
        })
      })

      # Sub-routers
      if (length(self$mounts) > 0){
        for(i in 1:length(self$mounts)){
          # Trim leading slash
          path <- sub("^/", "", names(self$mounts)[i])

          levels <- strsplit(path, "/", fixed=TRUE)[[1]]

          m <- self$mounts[[i]]
          paths <- addPath(paths, levels, m)
        }
      }

      lexisort <- function(paths) {
        if (is.list(paths)) {
          paths <- lapply(paths, lexisort)
          if (!is.null(names(paths))) {
            paths <- paths[order(names(paths))]
          }
        }
        paths
      }

      lexisort(paths)
    }
  ),
  private = list(

    default_serializer = NULL, # The default serializer for the router
    default_parsers = NULL, # The default parsers for the router

    ends = list(), # List of endpoints indexed by their pre-empted filter.
    filts = NULL, # Array of filters
    mnts = list(),

    envir = NULL, # The environment in which all API execution will be conducted
    filename = NULL, # The file which was plumbed
    lines = NULL, # The lines constituting the API
    parsed = NULL, # The parsed representation of the API
    globalSettings = list(info=list()), # Global settings for this API. Primarily used for OpenAPI Specification.
    disable_run = NULL, # Disable run method during parsing of the Plumber file

    errorHandler = NULL,
    notFoundHandler = NULL,
    maxSize = 0, # Max request size in bytes. (0 is a no-op)

    api_spec_handler = NULL,
    docs_info = NULL,
    docs_callback = NULL,
    debug = NULL,

    addFilterInternal = function(filter){
      # Create a new filter and add it to the router
      private$filts <- c(private$filts, filter)

      self
    },
    addEndpointInternal = function(ep, preempt){
      noPreempt <- missing(preempt) || is.null(preempt)

      filterNames <- "__first__"
      for (f in private$filts){
        filterNames <- c(filterNames, f$name)
      }
      if (!noPreempt && ! preempt %in% filterNames){
        if (!is.null(ep$lines)){
          stopOnLine(ep$lines[1], private$fileLines[ep$lines[1]], paste0("The given @preempt filter does not exist in this Plumber router: '", preempt, "'"))
        } else {
          stop(paste0("The given preempt filter does not exist in this Plumber router: '", preempt, "'"))
        }
      }

      if (noPreempt){
        preempt <- "__no-preempt__"
      }

      private$ends[[preempt]] <- c(private$ends[[preempt]], ep)
    },
    removeEndpointInternal = function(methods, path, preempt){
      noPreempt <- is.null(preempt)

      if (noPreempt){
        preempt <- "__no-preempt__"
      }
      toRemove <- vapply(
        private$ends[[preempt]],
        function(ep) {
          isTRUE(all(ep$verbs %in% methods)) && isTRUE(ep$path == path)
        },
        logical(1))

      private$ends[[preempt]][toRemove] <- NULL
    },

    routerSpecificationInternal = function(router, parentPath = "") {
      remove_trailing_slash <- function(x) {
        sub("[/]$", "", x)
      }
      remove_leading_slash <- function(x) {
        sub("^[/]", "", x)
      }
      join_paths <- function(x, y) {
        x <- remove_trailing_slash(x)
        y <- remove_leading_slash(y)
        paste(x, y, sep = "/")
      }

      # make sure to use the full path
      endpointList <- list()

      for (endpoint in router$endpoints) {
        for (endpointEntry in endpoint) {
          endpointSpec <- endpointSpecification(
            endpointEntry,
            join_paths(parentPath, endpointEntry$path)
          )
          endpointList <- utils::modifyList(endpointList, endpointSpec)
        }
      }

      # recursively gather mounted enpoint entries
      if (length(router$mounts) > 0) {
        for (mountPath in names(router$mounts)) {
          mountEndpoints <- private$routerSpecificationInternal(
            router$mounts[[mountPath]],
            join_paths(parentPath, mountPath)
          )
          endpointList <- utils::modifyList(endpointList, mountEndpoints)
        }
      }

      # returning a single list of OpenAPI Paths Objects
      endpointList
    }
  )
)



upgrade_docs_parameter <- function(docs, ...) {
  stopifnot(length(docs) == 1)
  stopifnot(is.logical(docs) || is.character(docs))
  if (isTRUE(docs)) {
    docs <- "swagger"
  }
  if (is.character(docs) && is_docs_available(docs)) {
    enabled <- TRUE
  } else {
    enabled <- FALSE
    docs <- "__not_enabled__"
  }

  list(
    enabled = enabled,
    docs = docs,
    args = list(...),
    has_not_been_set = FALSE
  )
}



default_debug <- function() {
  interactive()
}


urlHost <- function(scheme = "http", host, port, path = "", changeHostLocation = FALSE) {
  if (isTRUE(changeHostLocation)) {
    # upgrade callback location to be localhost and not catch-all addresses
    # shiny: https://github.com/rstudio/shiny/blob/95173f6/R/server.R#L781-L786
    if (identical(host, "0.0.0.0")) {
      # RStudio IDE does NOT like 0.0.0.0 locations.
      # Must use 127.0.0.1 instead.
      host <- "127.0.0.1"
    } else if (identical(host, "::")) {
      # upgrade ipv6 catch-all to ipv6 "localhost"
      host <- "::1"
    }
  }

  # if ipv6 address, surround in brackets
  if (grepl(":[^/]", host)) {
    host <- paste0("[", host, "]")
  }

  if (is.null(scheme) || !nzchar(scheme)) {
    scheme <- "http"
  }

  paste0(scheme, "://", host, ":", port, path)
}
