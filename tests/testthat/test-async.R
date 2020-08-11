

context("Promise")
library(promises) # reexports


# Block until all pending later tasks have executed
wait_for_async <- function() {
  skip_if_not_installed("later")
  while (!later::loop_empty()) {
    later::run_now()
    Sys.sleep(0.00001)
  }
}


get_result <- function(result) {
  if (!promises::is.promising(result)) {
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
  expect_false(promises::is.promising(x))
  invisible(x)
}
expect_promise <- function(x) {
  expect_true(promises::is.promising(x))
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
  pr %>%
    pr_set_serializer(serializer_identity()) %>%
    {
      pr <- .
      pr$call(make_req("GET", route))
    }
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

hooks <- c(
  # "preexec", "postexec", # can not execute
  "preserialize", "postserialize",
  "preroute", "postroute"
)

test_that("async hooks create async execution", {

  # exhaustive test of all public hooks

  # make an exhaustive matrix of T/F values of which hooks are async
  hooks_are_async <- do.call(
    expand.grid,
    lapply(stats::setNames(hooks, hooks), function(...) c(FALSE, TRUE))
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




context("Promise - multiple hooks can change the value")

test_that("async hooks change value being passed through",  {

  pr <- async_router()

  lapply(1:10, function(i) {
    pr$registerHook("preroute", function(...) {
      # no value arg
      promise_resolve(TRUE) # make execution in a promise
    })
  })
  lapply(seq(1, 20 - 1, by = 1), function(i) {
    pr$registerHook("postroute", function(value, ...) {
      expect_equal(value, i)
      value + 1
    })
  })
  # finishes at 20

  lapply(seq(20, 40 - 2, by = 2), function(i) {
    pr$registerHook("preserialize", function(value, ...) {
      expect_equal(value, i)
      value + 2
    })
  })
  # finishes at 40

  lapply(seq(40, 70 - 3, by = 3), function(i) {
    pr$registerHook("postserialize", function(value, ...) {
      # in return object format
      expect_equal(value$body, i)
      value$body <- value$body + 3
      value
    })
  })
  # finishes at 70

  pr %>%
    serve_route("/number-one") %>%
    expect_promise() %>%
    get_result() %>% {
      x <- .
      expect_equal(x$body, 70)
    }
})


context("Promise - errors are handled")

expect_route_error <- function(response, txt) {
  expect_equal(response$body$error, "500 - Internal server error")
  expect_true(grepl(txt, response$body$message))
}

test_that("sync error is caught", {
  bad_expression <- "sync-bad - expected error here"
  expect_output(
    {
      async_router() %>%
        pr_set_debug(TRUE) %>%
        serve_route("/sync-bad") %>%
        expect_not_promise() %>%
        get_result() %>%
        expect_route_error(bad_expression)
    },
    bad_expression
  )
})


test_that("async error is caught", {
  bad_expression <- "async-bad - expected error here"
  expect_output(
    {
      async_router() %>%
        pr_set_debug(TRUE) %>%
        serve_route("/async-bad") %>%
        expect_promise() %>%
        get_result() %>%
        expect_route_error(bad_expression)
    },
    bad_expression
  )
})




test_that("sync hook errors are caught", {

  check_hook <- function(hook) {
    bad_expression <- paste0("boom ", hook, " sync")
    pr <- async_router()
    pr$registerHook(hook, function(...) {
      # no value arg
      stop(bad_expression)
    })

    expect_output(
      {
        pr %>%
          pr_set_debug(TRUE) %>%
          serve_route("/sync") %>%
          expect_not_promise() %>%
          get_result() %>%
          expect_route_error(bad_expression)
      },
      bad_expression
    )
  }
  lapply(hooks, check_hook)
})


test_that("async hook errors are caught", {

  check_sync_error <- function(hook) {
    bad_expression <- paste0("boom ", hook, " sync")
    pr <- async_router()
    pr$registerHook("preroute", function(...) {
      # no value arg
      promise_resolve(TRUE) # make execution in a promise
    })

    pr$registerHook(hook, function(...) {
      # no value arg
      stop(bad_expression)
    })

    expect_output(
      {
        pr %>%
          pr_set_debug(TRUE) %>%
          serve_route("/sync") %>%
          expect_promise() %>%
          get_result() %>%
          expect_route_error(bad_expression)
      },
      bad_expression
    )
  }
  lapply(hooks, check_sync_error)

  check_async_error <- function(hook) {
    bad_expression <- paste0("boom ", hook, " sync")
    pr <- async_router()
    pr$registerHook("preroute", function(...) {
      # no value arg
      promise_resolve(TRUE) # make execution in a promise
    })

    pr$registerHook(hook, function(...) {
      # no value arg
      p <- promise_resolve(TRUE)
      p <- then(p, function(value) {
        stop(bad_expression)
      })
      p
    })

    expect_output(
      {
        pr %>%
          pr_set_debug(TRUE) %>%
          serve_route("/sync") %>%
          expect_promise() %>%
          get_result() %>%
          expect_route_error(bad_expression)
      },
      bad_expression
    )
  }
  lapply(hooks, check_async_error)
})
