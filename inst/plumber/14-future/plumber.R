
library(promises)
library(coro)
future::plan("multisession") # a worker for each core
# future::plan(future::multisession(workers = 2)) # only two workers


# Quick manual test:
# Within 10 seconds...
# 1. Visit /future
# 2. While /future is loading, visit /sync many times
# /future will not block /sync from being able to be loaded.


#' @serializer json list(auto_unbox = TRUE)
#' @get /sync
function() {
  # print route, time, and worker pid
  paste0("/sync; ", Sys.time(), "; pid:", Sys.getpid())
}

#' @contentType list(type = "text/html")
#' @serializer json list(auto_unbox = TRUE)
#' @get /future
function() {

  future_promise({
    # perform long running computations
    Sys.sleep(10)

    # print route, time, and worker pid
    paste0("/future; ", Sys.time(), "; pid:", Sys.getpid())
  })
}


# A function that will return a promise object
calc_using_promise <- function() {
  # Executes using `future`
  future_promise({
    # perform long computations
    Sys.sleep(1)

    # return which process id was used
    Sys.getpid()
  }) %...>% {
    exec_pid <- .
    main_pid <- Sys.getpid()
    # print route, time, and worker pid
    paste0("/coro; ", Sys.time(), "; exec pid:", exec_pid, "; main pid:", main_pid)

    list(exec_pid = exec_pid, main_pid = main_pid)
  }
}

#' For more info about `coro`, visit https://coro.r-lib.org
#' @contentType text
#' @serializer json list(auto_unbox = TRUE)
#' @get /coro
async(function() {

  # (a)wait for the promised value and use as a regular value
  # No need for a followup promise when using `await(p)`
  pids <- await(calc_using_promise())

  # Write code with the finalized async value as if it was synchronously found
  pids$exec_is_even <- pids$exec_pid %% 2 == 0

  # return info
  pids
})


# -----------------------------------


# Originally by @antoine-sachet from https://github.com/rstudio/plumber/issues/389
#' @get /divide
#' @serializer json list(auto_unbox = TRUE)
#' @param a number
#' @param b number
function(a = NA, b = NA) {
  future_promise({
    a <- as.numeric(a)
    b <- as.numeric(b)
    if (is.na(a)) stop("a is missing")
    if (is.na(b)) stop("b is missing")
    if (b == 0) stop("Cannot divide by 0")

    a / b
  })
}

#' @get /divide-catch
#' @serializer json list(auto_unbox = TRUE)
#' @param a number
#' @param b number
function(a = NA, b = NA) {
  future_promise({
    a <- as.numeric(a)
    b <- as.numeric(b)
    if (is.na(a)) stop("a is missing")
    if (is.na(b)) stop("b is missing")
    if (b == 0) stop("Cannot divide by 0")

    a / b
  }) %...!%
    # Handle `future` errors
    {
      error <- .
      # handle error here!
      if (error$message == "b is missing") {
        return(Inf)
      }

      # rethrow original error
      stop(error)
    }
}
