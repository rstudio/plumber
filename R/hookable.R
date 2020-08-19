#' @keywords internal
#' @title Hookable
Hookable <- R6Class(
  "Hookable",
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
