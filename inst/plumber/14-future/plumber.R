
library(promises)
library(future)

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

  future({
    # perform large computations
    Sys.sleep(10)

    # print route, time, and worker pid
    paste0("/future; ", Sys.time(), "; pid:", Sys.getpid())
  })
}


# -----------------------------------


# Originally by @antoine-sachet from https://github.com/rstudio/plumber/issues/389
#' @get /divide
#' @serializer json list(auto_unbox = TRUE)
#' @param a number
#' @param b number
function(a = NA, b = NA) {
  future({
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
  future({
    a <- as.numeric(a)
    b <- as.numeric(b)
    if (is.na(a)) stop("a is missing")
    if (is.na(b)) stop("b is missing")
    if (b == 0) stop("Cannot divide by 0")

    a / b
  }) %>%
    # Handle `future` errors
    promises::catch(function(error) {
      # handle error here!
      if (error$message == "b is missing") {
        return(Inf)
      }

      # rethrow original error
      stop(error)
    })
}
