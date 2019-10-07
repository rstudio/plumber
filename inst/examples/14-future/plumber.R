
library(promises)
library(future)

future::plan("multiprocess") # use all available cores
# future::plan(future::multiprocess(workers = 2)) # only two cores

# Quick manual test:
# Within 10 seconds...
# 1. Visit /future
# 2. While /future is loading, visit /sync many times
# /future will not block /sync from being able to be loaded.


#' @json(auto_unbox = TRUE)
#' @get /sync
function() {
  # print route, time, and worker pid
  paste0("/sync; ", Sys.time(), "; pid:", Sys.getpid())
}

#' @contentType list(type = "text/html")
#' @json(auto_unbox = TRUE)
#' @get /future
function() {

  future({
    # perform large computations
    Sys.sleep(10)

    # print route, time, and worker pid
    paste0("/future; ", Sys.time(), "; pid:", Sys.getpid())
  })
}
