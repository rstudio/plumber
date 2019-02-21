
# Visit /async
# While /async is loading, visit /sync many times

library(promises)

add_async_sleep <- function(p) {
  for (i in 1:10) {
    p <- then(p, function(value) {
      value
    })
  }
  p
}

# use name_ as a placeholder for name when there are extra args
time <- function(name_, name = name_) {
  list(
    name = name,
    time = as.numeric(Sys.time())
  )
}

new_promise <- function() {
  promise_resolve(TRUE)
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

#' @get /async-bad
function() {
  new_promise() %>%
    add_async_sleep() %...>%
    stop("async-bad - expected error here")
}

#' @get /sync-bad
function() {
  stop("sync-bad - expected error here")
}
