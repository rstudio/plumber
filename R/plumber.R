#' @import R6
#' @import stringi
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
  postBody = postBodyFilter,
  cookieParser = cookieFilter,
  sharedSecret = sharedSecretFilter
)

#' @keywords internal
#' @title hookable
hookable <- R6Class(
  "hookable",
  public=list(
    #' @description Register a hook on a router
    #' @param stage a character string.
    #' @param handler a hook function.
    registerHook = function(stage, handler){
      private$hooks[[stage]] <- c(private$hooks[[stage]], handler)
    },
    #' @description Register hooks on a router
    #' @param handlers a named list of hook functions.
    registerHooks = function(handlers){
      for (i in 1:length(handlers)){
        stage <- names(handlers)[i]
        h <- handlers[[i]]

        self$registerHook(stage, h)
      }
    }
  ), private=list(
    hooks = list( ),

    # Because we're passing in a `value` argument here, `runHooks` will return either the
    # unmodified `value` argument back, or will allow one or more hooks to modify the value,
    # in which case the modified value will be returned. Hooks declare that they intend to
    # modify the value by accepting a parameter named `value`, in which case their returned
    # value will be used as the updated value.
    runHooks = function(stage, args) {
      if (missing(args)) {
        args <- list()
      }

      stageHooks <- private$hooks[[stage]]
      if (length(stageHooks) == 0) {
        # if there is nothing to execute, return early
        return(args$value)
      }

      runSteps(
        NULL,
        errorHandlerStep = stop,
        append(
          unlist(lapply(stageHooks, function(stageHook) {
            stageHookArgs <- list()
            list(
              function(...) {
                stageHookArgs <<- getRelevantArgs(args, plumberExpression = stageHook)
              },
              function(...) {
                do.call(stageHook, stageHookArgs) #TODO: envir=private$envir?
              },
              # `do.call` could return a promise. Wait for it's return value
              # if "value" exists in the original args, overwrite it for futher execution
              function(value, ...) {
                if ("value" %in% names(stageHookArgs)) {
                  # Special case, retain the returned value from the hook
                  # and pass it in as the value for the next handler.
                  # Ultimately, return value from this function
                  args$value <<- value
                }
                NULL
              }
            )
          })),
          list(
            function(...) {
              # Return the value as passed in or as explcitly modified by one or more hooks.
              return(args$value)
            }
          )
        )
      )
    }
  )
)


#' Package Plumber Router
# ' @details Routers are the core request handler in plumber. A router is responsible for
# ' taking an incoming request, submitting it through the appropriate filters and
# ' eventually to a corresponding endpoint, if one is found.
# '
# ' See \url{http://www.rplumber.io/articles/programmatic-usage.html} for additional
# ' details on the methods available on this object.
#' @export
plumber <- R6Class(
  "plumber",
  inherit = hookable,
  public = list(
    #' @description Create a new `plumber` router
    #'
    #' See also [plumb()], [pr()]
    #' @param filters a list of plumber filters
    #' @param file path to file to plumb
    #' @param envir an environment to be used as the enclosure for the routers execution
    #' @return A new `plumber` router
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
      private$maxSize <- getOption('plumber.maxRequestSize', 0) #0  Unlimited
      self$setSerializer(serializer_json())
      # Default parsers to maintain legacy features
      self$set_parsers(c("json", "form", "text", "octet", "multi"))
      self$setErrorHandler(defaultErrorHandler())
      self$set404Handler(default404Handler)
      self$set_ui()
      private$ui_info$has_not_been_set <- TRUE # set to know if `$set_ui()` has been called before `$run()`
      self$set_ui_callback()
      self$set_debug()
      self$set_api_spec()

      # Add in the initial filters
      for (fn in names(filters)){
        fil <- PlumberFilter$new(fn, filters[[fn]], private$envir, private$default_serializer, NULL)
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

        for (i in 1:length(private$parsed)){
          e <- private$parsed[i]

          srcref <- attr(e, "srcref")[[1]][c(1,3)]

          evaluateBlock(srcref, private$lines, e, private$envir, private$addEndpointInternal,
                        private$addFilterInternal, self)
        }

        private$globalSettings <- plumbGlobals(private$lines)
      }

    },
    #' @description Start a server using `plumber` object.
    #'
    #' See also: [pr_run()]
    #' @param host a string that is a valid IPv4 or IPv6 address that is owned by
    #' this server, which the application will listen on. "0.0.0.0" represents
    #' all IPv4 addresses and "::/0" represents all IPv6 addresses.
    #' @param port a number or integer that indicates the server port that should
    #' be listened on. Note that on most Unix-like systems including Linux and
    #' Mac OS X, port numbers smaller than 1025 require root privileges.
    #'
    #' This value does not need to be explicitly assigned. To explicity set it, see [options_plumber()].
    #' @param debug Deprecated. See `$set_debug()`
    #' @param swagger Deprecated. See `$set_ui(ui)` or `$set_api_spec()`
    #' @param swaggerCallback Deprecated. See `$set_ui_callback()`
    run = function(
      host = '127.0.0.1',
      port = getOption('plumber.port', NULL),
      swagger = stop("deprecated"),
      debug = stop("deprecated"),
      swaggerCallback = stop("deprecated")
    ) {

      if (isTRUE(private$disable_run)) {
        stop("Plumber router `$run()` method should not be called while `plumb()`ing a file")
      }

      # Legacy support for RStudio pro products.
      # Checks must be kept for >= 2 yrs after plumber v1.0.0 release date
      if (!missing(debug)) {
        message("`$run(debug)` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$set_debug(debug)`")
        self$set_debug(debug)
      }
      if (!missing(swagger)) {
        if (is.function(swagger)) {
          # between v0.4.6 and v1.0.0
          message("`$run(swagger)` has been deprecated in v1.0.0 and will be removed in a coming release. To alter the swagger spec, please use `$set_api_spec(api)`")
          self$set_api_spec(swagger)
          # spec is now enabled by default. Do not alter
        } else {
          if (isTRUE(private$ui_info$has_not_been_set)) {
            # <= v0.4.6
            message("`$run(swagger)` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$set_ui(ui)`")
            self$set_ui(swagger)
          } else {
            # $set_ui() has been called (other than during initialization).
            # Believe that it is the correct behavior
            # Warn about updating the run method
            message(
              "`$run(swagger)` has been deprecated in v1.0.0 and will be removed in a coming release.\n",
              "The plumber UI has already been set. Ignoring `swagger` parameter.\n",
              "Please update your `$run()` method."
            )
          }
        }
      }
      if (!missing(swaggerCallback)) {
        message("`$run(swaggerCallback)` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$set_ui_callback(callback)`")
        self$set_ui_callback(swaggerCallback)
      }

      port <- findPort(port)

      message("Running plumber API at ", urlHost(host = host, port = port, changeHostLocation = FALSE))

      # Set and restore the wd to make it appear that the proc is running local to the file's definition.
      if (!is.null(private$filename)) {
        old_wd <- setwd(dirname(private$filename))
        on.exit({setwd(old_wd)}, add = TRUE)
      }

      if (isTRUE(private$ui_info$enabled)) {
        mount_ui(
          pr = self,
          host = host,
          port = port,
          ui_info = private$ui_info,
          callback = private$ui_callback
        )
        on.exit(unmount_ui(self, private$ui_info), add = TRUE)
      }

      on.exit(private$runHooks("exit"), add = TRUE)

      httpuv::runServer(host, port, self)
    },
    #' @description Mount a plumber router
    #'
    #' Plumber routers can be “nested” by mounting one into another
    #' using the `mount()` method. This allows you to compartmentalize your API
    #' by paths which is a great technique for decomposing large APIs into smaller files.
    #'
    #' See also: [pr_mount()]
    #' @param path a character string. Where to mount router.
    #' @param router a plumber router. Router to be mounted.
    #' @examples
    #' \dontrun{
    #' root <- pr()
    #'
    #' users <- plumber$new("users.R")
    #' root$mount("/users", users)
    #'
    #' products <- plumber$new("products.R")
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
    #' @description Unmount a plumber router
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
    #' @description Register a hook
    #'
    #' See also: [pr_hook()], [pr_hooks()]
    #' @param stage a character string. Point in the lifecycle of a request.
    #' @param handler a hook function.
    #' @details Plumber routers support the notion of "hooks" that can be registered
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
    #' @param ... additional arguments for `PlumberEndpoint` creation
    #' @examples
    #' \dontrun{
    #' pr <- pr()
    #' pr$handle("GET", "/", function(){
    #'   "<html><h1>Programmatic Plumber!</h1></html>"
    #' }, serializer=plumber::serializer_html())
    #' }
    handle = function(methods, path, handler, preempt, serializer, parsers, endpoint, ...) {
      epdef <- !missing(methods) || !missing(path) || !missing(handler) || !missing(serializer) || !missing(parsers)
      if (!missing(endpoint) && epdef){
        stop("You must provide either the components for an endpoint (handler and serializer) OR provide the endpoint yourself. You cannot do both.")
      }

      if (epdef) {
        if (missing(serializer)) {
          serializer <- private$default_serializer
        }
        if (missing(parsers)) {
          parsers <- private$parsers
        }

        endpoint <- PlumberEndpoint$new(methods, path, handler, private$envir, serializer, parsers, ...)
      }
      private$addEndpointInternal(endpoint, preempt)
    },
    #' @description Remove endpoints
    #' @param methods a character string. http method.
    #' @param path a character string. Api endpoints
    #' @param preempt a preempt function.
    remove_handle = function(methods, path, preempt = NULL){
      private$removeEndpointInternal(methods, path, preempt)
    },
    #' @description Print representation of plumber router.
    #' @param prefix a character string. Prefix to append to representation.
    #' @param topLevel a logical value. When method executed on top level
    #' router, set to `TRUE`.
    #' @param ... additional arguments for recursive calls
    #' @return A terminal friendly represention of a plumber router.
    print = function(prefix="", topLevel=TRUE, ...){
      endCount <- as.character(sum(unlist(lapply(self$endpoints, length))))

      # Reference on box characters: https://en.wikipedia.org/wiki/Box-drawing_character

      cat(prefix)
      if (!topLevel){
        cat("\u2502 ") # "| "
      }
      cat(crayon::silver("# Plumber router with ", endCount, " endpoint", ifelse(endCount == 1, "", "s"),", ",
                         as.character(length(private$filts)), " filter", ifelse(length(private$filts) == 1, "", "s"),", and ",
                         as.character(length(self$mounts)), " sub-router", ifelse(length(self$mounts) == 1, "", "s"),".\n", sep=""))

      if(topLevel){
        cat(prefix, crayon::silver("# Call run() on this object to start the API.\n"), sep="")
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

        } else if (inherits(node, "plumber")){
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
              names(node) == ""
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

      invisible(self)
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

      # These situations should NOT happen as req,res are set in self$call()
      # For testing purposes, these checks are added
      if (is.null(req$args)) {
        req$args <- list(req = req, res = res)
      } else {
        if (is.null(req$args$req)) {
          req$args$req <- req
        }
        if (is.null(req$args$res)) {
          req$args$res <- res
        }
      }

      path <- req$PATH_INFO
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
          req$argsPath <- h$getPathParams(path)
          req$argsPostBody <- postbody_parser(req, parsers)

          req$args <- c(
            # req, res
            # query string params and any other `req$args`
            ## Query string params have been added to `req$args`.
            ## At this point, can not include both `req,res` and `req$argsQuery`. So using `req$args`
            req$args,
            # path params
            req$argsPath,
            # post body params
            req$argsPostBody
          )

          return(do.call(h$exec, req$args))
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
            do.call(fi$exec, req$args)
          }
          postFilterStep <- function(fres, ...) {
            if (hasForwarded()) {
              # return like normal
              return(fres)
            }
            # forward() wasn't called, presumably meaning the request was
            # handled inside of this filter.
            if (!is.null(fi$serializer)){
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

          if (nchar(path) >= nchar(mountPath) && substr(path, 0, nchar(mountPath)) == mountPath) {
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
    #' @description httpuv interface call function
    #' @param req request object
    #' @details required for httpuv interface
    call = function(req) {
      # Set the arguments to an empty list
      req$pr <- self
      req$.internal <- new.env()

      res <- PlumberResponse$new(private$default_serializer)
      req$args <- list(req = req, res = res)

      # maybe return a promise object
      self$serve(req, res)
    },
    #' @description httpuv interface onHeaders function
    #' @param req request object
    #' @details required for httpuv interface
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
    #' @description httpuv interface onWSOpen function
    #' @param ws WebSocket object
    #' @details required for httpuv interface
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
    #' @description Sets the default parsers of the router.
    #' @details Initialized to `c("json", "form", "text", "octet", "multi")`
    #' @template pr_set_parsers__parsers
    set_parsers = function(parsers) {
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
    #' @description Set UI to use for API
    #'
    #' See also: [pr_set_ui()], [register_ui()], [registered_uis()]
    #' @param ui a character value or a logical value. Defaults to `options("plumber.ui"). See [pr_set_ui()] for examples.
    #'  If using [options_plumber()], the value must be set before initializing your Plumber router.
    #' @param ... Other params to be passed to `ui` functions.
    set_ui = function(
      ui = getOption("plumber.ui", TRUE),
      ...
    ) {
      stopifnot(length(ui) == 1)
      stopifnot(is.logical(ui) || is.character(ui))
      if (isTRUE(ui)) {
        ui <- "swagger"
      }
      if (is.character(ui) && is_ui_available(ui)) {
        enabled <- TRUE
      } else {
        enabled <- FALSE
        ui <- "__not_enabled__"
      }
      private$ui_info <- list(
        enabled = enabled,
        ui = ui,
        args = list(...)
      )
    },
    #' @description Set UI callback to notify where the API is located.
    #'
    #' When set, it will be called with a character string corresponding
    #' to the API UI url. This allows RStudio to open `swagger` UI when a
    #' Plumber router [pr_run()] method is executed.
    #'
    #' If using [options_plumber()], the value must be set before initializing your Plumber router.
    #'
    #' See also: [pr_set_ui_callback()]
    #' @param callback a callback function for taking action on UI url. (Also accepts `NULL` values to disable the `callback`.)
    set_ui_callback = function(
      callback = getOption('plumber.ui.callback', getOption('plumber.swagger.url', NULL))
    ) {
      # Use callback when defined
      if (!length(callback) || !is.function(callback)) {
        callback <- function(...) { NULL }
      }
      if (length(formals(callback)) == 0) {
        stop("`callback` must accept at least 1 argument. (`api_url`)")
      }
      private$ui_callback <- callback
    },
    #' @description Set debug value to include error messages
    #'
    #' See also: `$get_debug()` and [pr_set_debug()]
    #' @param debug `TRUE` provides more insight into your API errors.
    set_debug = function(debug = interactive()) {
      stopifnot(length(debug) == 1)
      private$debug <- isTRUE(debug)
    },
    #' @description Retrieve the `debug` value.
    #'
    #' See also: `$get_debug()` and [pr_set_debug()]
    get_debug = function() {
      private$debug
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
    #' Add a function to customize what is returned in `$get_api_spec()`.
    #'
    #' Note, the returned value will be sent through [serializer_unboxed_json()] which will turn all length 1 vectors into atomic values.
    #' To force a vector to serialize to an array of size 1, be sure to call [as.list()] on your value. `list()` objects are always serialized to an array value.
    #'
    #' See also: [pr_set_api_spec()]
    #' @param api This can be
    #'   * an OpenAPI Specification formatted list object
    #'   * a function that accepts the OpenAPI Specification autogenerated by `plumber` and returns a OpenAPI Specification formatted list object.
    #'
    #'  The value returned will not be validated for OAS compatibility.
    set_api_spec = function(api = NULL) {
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
    #' @description Retrieve openAPI file
    get_api_spec = function() { #FIXME: test

      routerSpec <- private$routerSpecificationInternal(self)

      # Extend the previously parsed settings with the endpoints
      def <- utils::modifyList(private$globalSettings, list(paths = routerSpec))

      # Lay those over the default globals so we ensure that the required fields
      # (like API version) are satisfied.
      ret <- utils::modifyList(defaultGlobals, def)

      ret <- private$api_spec_handler(ret)

      # remove NA or NULL values, which UI parsers do not like
      ret <- removeNaOrNulls(ret)

      ret
    },


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
    #' @details addFilter has been deprecated in v0.4.0 and will be removed in a coming release. Please use `filter` instead.
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
    #' @details addGlobalProcessor has been deprecated in v0.4.0 and will be removed in a coming release. Please use `registerHook`(s) instead.
    #' @param proc proc
    addGlobalProcessor = function(proc){
      warning("addGlobalProcessor has been deprecated in v0.4.0 and will be removed in a coming release. Please use `registerHook`(s) instead.")
      self$registerHooks(proc)
    },
    #' @description Deprecated. Retrieve openAPI file
    openAPIFile = function() {
      warning("`$openAPIFile()` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$get_api_spec()`.")
      self$get_api_spec()
    },
    #' @description Deprecated. Retrieve openAPI file
    swaggerFile = function() {
      warning("`$swaggerFile()` has been deprecated in v1.0.0 and will be removed in a coming release. Please use `$get_api_spec()`.")
      self$get_api_spec()
    }
  ), active = list(
    #' @field endpoints plumber router endpoints read-only
    endpoints = function(){
      private$ends
    },
    #' @field filters plumber router filters read-only
    filters = function(){
      private$filts
    },
    #' @field mounts plumber router mounts read-only
    mounts = function(){
      private$mnts
    },
    #' @field environment plumber router environment read-only
    environment = function() {
      private$envir
    },
    #' @field routes plumber router routes read-only
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
        node[[children[1]]] <- addPath(node[[children[1]]], children[-1], endpoint)
        node
      }

      lapply(self$endpoints, function(ends){
        lapply(ends, function(e){
          # Trim leading slash
          path <- sub("^/", "", e$path)

          levels <- strsplit(path, "/", fixed=TRUE)[[1]]
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

      # TODO: Sort lexicographically

      paths
    }
  ), private = list(
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
    maxSize = NULL, # Max request size in bytes

    api_spec_handler = NULL,
    ui_info = NULL,
    ui_callback = NULL,
    debug = NULL,

    addFilterInternal = function(filter){
      # Create a new filter and add it to the router
      private$filts <- c(private$filts, filter)
      invisible(self)
    },
    addEndpointInternal = function(ep, preempt){
      noPreempt <- missing(preempt) || is.null(preempt)

      filterNames <- "__first__"
      for (f in private$filts){
        filterNames <- c(filterNames, f$name)
      }
      if (!noPreempt && ! preempt %in% filterNames){
        if (!is.null(ep$lines)){
          stopOnLine(ep$lines[1], private$fileLines[ep$lines[1]], paste0("The given @preempt filter does not exist in this plumber router: '", preempt, "'"))
        } else {
          stop(paste0("The given preempt filter does not exist in this plumber router: '", preempt, "'"))
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
