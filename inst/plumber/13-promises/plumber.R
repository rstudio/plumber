
# Visit /async
# While /async is loading, visit /sync many times

library(promises)

sleep_count <- 5
# add 5 seconds of sleep time
add_async_sleep <- function(p) {
  n <- 20
  for (i in 1:(sleep_count * n)) {
    p <- then(p, function(value) {
      Sys.sleep(1/n)
      "" # return value
    })
  }
  p
}

# use name_ as a placeholder for name when there are extra args
time <- function(name_, name = name_) {
  paste0(name, ": ", Sys.time())
}

new_promise <- function() {
  promise(function(resolve, reject){ resolve(NULL) })
}

#' @get /async
function() {
  new_promise() %>%
    add_async_sleep() %...>%
    time("async")
}

#' @get /sync
function() {
  time("sync")
}
#' @get /sync-slow
function() {
  Sys.sleep(sleep_count)
  time("sync-slow")
}

#' @get /async-bad
function() {
  new_promise() %>%
    add_async_sleep() %...>%
    stop("async-bad - expected error here") %>%
    add_async_sleep() %...>%
    time("async-bad")
}

#' @get /sync-bad
function() {
  stop("sync-bad - expected error here")
}
