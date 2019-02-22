
runStepsIfForwarding <- function(initialValue, errorHandlerStep, steps) {
  runStepsUntil(
    initialValue = initialValue,
    errorHandlerStep = errorHandlerStep,
    conditionFn = function(value) {
      !hasForwarded()
    },
    steps = steps
  )
}


withWarn1 <- function(expr) {
  oldWarn <- options("warn")[[1]]
  on.exit({
    options(warn = oldWarn)
  })
  options(warn = 1)

  force(expr)
}


runSteps <- function(initialValue, errorHandlerStep, steps) {
  runStepsUntil(
    initialValue,
    errorHandlerStep,
    function(x) {
      # always continue
      FALSE
    },
    steps
  )
}

#' @import promises
runStepsUntil <- function(initialValue, errorHandlerStep, conditionFn, steps) {
  x <- initialValue

  stepCount <- length(steps)
  nextStepPos <- 1L

  runStep <- function() {
    if (nextStepPos > stepCount) {
      return(x)
    }

    nextStep <- steps[[nextStepPos]]
    nextStepPos <<- nextStepPos + 1L # TODO pass in as value? multisession issue
    # if NULL is passed in (or not a function), it is skipped
    if (is.null(nextStep)) {
      return(runStep())
    }
    if (!is.function(nextStep)) {
      stop("runStepsUntil only knows how to handle functions or NULL values. Received something of classes: ", paste0(class(nextStep), collapse = ", "))
    }

    res <- nextStep(x)
    if (is.promising(res)) {
      res %...>% (function(value) {
        # message("WAITED!")
        x <<- value
        if (conditionFn(x)) {
          return(x)
        } else {
          return(runStep())
        }
      }) %...!% errorHandlerStep
    } else {
      tryCatch(
        {
          x <<- res
          if (conditionFn(x)) {
            return(x)
          } else {
            return(runStep())
          }
        },
        error = errorHandlerStep
      )
    }
  }

  tryCatch(runStep(), error = errorHandlerStep)
}





# steps_one <- list(
#   function(x) {
#     print("Got here 1")
#     1 # not a promise
#   },
#   function(x) {
#     stopifnot(x == 1)
#     print("Got here 2")
#     promise_resolve(2)
#   },
#   function(x) {
#     stopifnot(x == 2)
#     print("Got here 3")
#     3
#   },
#   function(x) {
#     stopifnot(x == 3)
#     print("Got here 4")
#     4
#   }
# )
#
# steps_two <- list(
#   function(x) {
#     runStep(steps_one, x)
#   },
#   function(x) {
#     print("Got here 1a")
#     1 # not a promise
#   },
#   function(x) {
#     print("Got here 2a")
#     2 # not a promise
#   }
# )
#
# runStep(steps_two); print("END")


currentExecName <- "currentExec"
getCurrentExec <- function() {
  .globals[[currentExecName]]
}
withCurrentExecDomain <- function(req, res, expr) {
  # Create a new environment for this particular request/response
  execEnv <- new.env(parent = emptyenv())
  execEnv$req <- req
  execEnv$res <- res

  domain <- createVarPromiseDomain(.globals, currentExecName, execEnv)
  promises::with_promise_domain(domain, expr)
}



# From Shiny.
# Creates a promise domain that always ensures `env[[name]] == value` when
# any code is being run in this domain.
createVarPromiseDomain <- function(env, name, value) {
  force(env)
  force(name)
  force(value)

  promises::new_promise_domain(
    wrapOnFulfilled = function(onFulfilled) {
      function(...) {
        orig <- env[[name]]
        env[[name]] <- value
        on.exit(env[[name]] <- orig)

        onFulfilled(...)
      }
    },
    wrapOnRejected = function(onRejected) {
      function(...) {
        orig <- env[[name]]
        env[[name]] <- value
        on.exit(env[[name]] <- orig)

        onRejected(...)
      }
    },
    wrapSync = function(expr) {
      orig <- env[[name]]
      env[[name]] <- value
      on.exit(env[[name]] <- orig)

      force(expr)
    }
  )
}
