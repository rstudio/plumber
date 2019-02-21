

context("Promises")
library(promises) # reexports


# Block until all pending later tasks have executed
wait_for_async <- function() {
  while (!later::loop_empty()) {
    later::run_now()
    Sys.sleep(0.00001)
  }
}


get_result <- function(result) {
  if (!promises::is.promise(result)) {
    return(result)
  }


  # return async value... synchronously
  ret <- NULL
  err <- NULL
  set_result <- function(value) {
    ret <<- value
  }
  result %...>% set_result() %...!% (function(error_value) {
    err <<- error_value
  })
  wait_for_async()
  if (!is.null(err)) {
    stop(err)
  }
  ret
}

expect_not_promise <- function(x) {
  expect_false(promises::is.promise(x))
  invisible(x)
}
expect_promise <- function(x) {
  expect_true(promises::is.promise(x))
  invisible(x)
}

expect_route_sync <- function(x) {
  expect_equal(x$body$name, "sync")
  invisible(x)
}
expect_route_async <- function(x) {
  expect_equal(x$body$name, "async")
  invisible(x)
}

async_router <- function() {
  "files/async.R" %>%
    test_path() %>%
    plumber$new()
}

serve_route <- function(pr, route) {

  pr$serve(
    make_req("GET", route),
    PlumberResponse$new(nullSerializer())
  )
}


test_that("sync works", {
  async_router() %>%
    serve_route("/sync") %>%
    expect_not_promise() %>%
    get_result() %>%
    expect_route_sync()
})

test_that("async works", {
  async_router() %>%
    serve_route("/async") %>%
    expect_promise() %>%
    get_result() %>%
    expect_route_async()
})


context("Promise - hooks")

test_that("async hooks create async execution", {

  # exhaustive test of all public hooks

  hooks <- c(
    "preserialize", "postserialize",
    "preroute", "postroute"
  )
  # make an exhaustive matrix of T/F values of which hooks are async
  hooks_are_async <- do.call(
    expand.grid,
    lapply(setNames(hooks, hooks), function(...) c(FALSE, TRUE))
  )

  # remove the all FALSE row
  hooks_are_async <- hooks_are_async[-1, ]
  # make sure there is at least one async hook
  expect_true(all(apply(hooks_are_async, 1, sum) > 0))

  # for each row in `hooks_are_async`
  apply(hooks_are_async, 1, function(hooks_are_async_row) {
    async_hook_count <- 0
    async_hook <- function(...) {
      args <- list(...)
      p <- promise_resolve(args$value)
      # add extra promises
      for (i in 1:10) {
        p <- then(p, function(val) {
          val
        })
      }
      # increment the counter
      p <- then(p, function(val) {
        async_hook_count <<- async_hook_count + 1
        val
      })
      p
    }
    pr <- async_router()
    # for each hook, register it if it should be async
    for (hook in hooks) {
      hook_is_async <- hooks_are_async_row[[hook]]
      if (hook_is_async) {
        pr$registerHook(hook, async_hook)
      }
    }
    # run the sync route with some async hooks
    pr %>%
      serve_route("/sync") %>%
      expect_promise() %>%
      get_result() %>%
      expect_route_sync()
    # make sure all the hooks were hit once
    expect_equal(async_hook_count, sum(hooks_are_async_row))
  })

})
