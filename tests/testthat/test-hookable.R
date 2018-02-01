context("hookable")

test_that("simple extension works", {
  simpleHook <- R6Class(
    "simplehook",
    inherit = hookable,
    public = list(
      exercise = function(hookName, args){
        private$runHooks(hookName, args)
      }
    )
  )

  events <- NULL
  s <- simpleHook$new()
  s$registerHook("abcd", function(arg1){
    events <<- c(events, arg1)
  })

  s$registerHook("defg", function(arg2){
    events <<- c(events, arg2)
  })

  expect_null(events)

  s$exercise("abcd", list(arg1="arg1here", unused="test"))
  expect_equal(events, "arg1here")

  s$exercise("defg", list(arg2="arg2here"))
  expect_equal(events, c("arg1here", "arg2here"))
})

test_that("registerHooks works", {
  simpleHook <- R6Class(
    "simplehook",
    inherit = hookable,
    public = list(
      exercise = function(hookName, args){
        private$runHooks(hookName, args)
      }
    )
  )

  events <- NULL
  s <- simpleHook$new()
  s$registerHooks(list(
    defg = function(arg2){
      events <<- c(events, arg2)
    }, abcd = function(arg1){
      events <<- c(events, arg1)
    }))

  expect_null(events)

  s$exercise("abcd", list(arg1="arg1here", unused="test"))
  expect_equal(events, "arg1here")

  s$exercise("defg", list(arg2="arg2here"))
  expect_equal(events, c("arg1here", "arg2here"))
})

test_that("overloading extension works", {
  simpleHook <- R6Class(
    "simplehook",
    inherit = hookable,
    public = list(
      registerHook = function(hook=c("hook1", "hook2"), fun){
        hook <- match.arg(hook)
        super$registerHook(hook, fun)
      },
      exercise = function(hookName, args){
        private$runHooks(hookName, args)
      }
    )
  )

  s <- simpleHook$new()
  expect_error(s$registerHook("abcd", function(arg1){
      events <<- c(events, arg1)
    })
  )

  events <- NULL
  s$registerHook("hook2", function(){
    events <<- c(events, "hook2!")
  })

  expect_null(events)

  # Works with missing args
  s$exercise("hook2")
  expect_equal(events, "hook2!")
})

test_that("value forwarding works across stacked hooks", {
  simpleHook <- R6Class(
    "simplehook",
    inherit = hookable,
    public = list(
      exercise = function(hookName, args){
        private$runHooks(hookName, args)
      }
    )
  )

  increment <- function(value){
    value + 1
  }

  s <- simpleHook$new()
  s$registerHook("valForward", increment)

  # Register the same hook twice. Should see the value increment by two each call since the
  # values are getting forwarded from the first hook into the second.
  s$registerHook("valForward", increment)

  s$registerHook("noVal", function(){
    # Doesn't take a value parameter, so shouldn't be treated specially for value handling.
    return(3)
  })

  v <- s$exercise("valForward", list(value=0))
  expect_equal(v, 2)
  v <- s$exercise("noVal", list(value=0))
  expect_equal(v, 0)
})
