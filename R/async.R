
runStepsIfForwarding <- function(initialValue, errorHandlerStep, steps) {
  runStepsUntil(
    initialValue = initialValue,
    errorHandlerStep = errorHandlerStep,
    conditionFn = function(x) {
      !is_forward(x)
    },
    steps = steps
  )
}



tryCatchWarn <- function(error, expr) {
  oldWarn <- options("warn")[[1]]
  tryCatch(
    {
      # Set to show warnings immediately as they happen.
      options(warn=1)

      force(expr)
    },
    error = error,
    finally = {
      options(warn = oldWarn)
    }
  )
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

  step_count <- length(steps)
  nextStepPos <- 1L

  runStep <- function() {
    if (nextStepPos > step_count) {
      return(x)
    }

    nextStep <- steps[[nextStepPos]]
    nextStepPos <<- nextStepPos + 1L # TODO pass in as value? multisession issue
    # if NULL is passed in (or not a function), it is skipped
    if (!is.function(nextStep)) {
      return(runStep())
    }

    res <- nextStep(x)
    if (is.promising(res)) {
      res %...>% (function(value) {
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

  runStep()
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
