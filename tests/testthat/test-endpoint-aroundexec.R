test_that("aroundexec function wrap like onions", {

  r <- PlumberEndpoint$new(
    'verb', '/path',
    expr = function(n = 100) {
      cat("exec\n")
      n
    },
    envir = new.env(parent = globalenv())
  )

  i <- 0
  expected_sum <- 100
  register_hook <- function(stage) {
    i <<- i + 1
    ii <- force(i)
    switch(stage,
      "preexec" = {
        r$registerHook(stage, function(req, res) {
          cat("preexec ", ii, "\n", sep = "")
          NULL
        })
      },
      "postexec" = {
        expected_sum <<- expected_sum + ii
        r$registerHook(stage, function(value, req, res, data) {
          cat("postexec ", ii, "\n", sep = "")
          value + ii
        })
      },
      "aroundexec" = {
        expected_sum <<- expected_sum + ii
        r$registerHook(stage, function(..., .next) {
          cat("aroundexec pre ", ii, "\n", sep = "")
          value <- .next(...)
          cat("aroundexec post ", ii, "\n", sep = "")
          value + ii
        })
      },
      stop("not a valid hook stage!")
    )
  }
  register_hook("preexec")
  register_hook("aroundexec")
  register_hook("postexec")

  register_hook("preexec")
  register_hook("postexec")
  register_hook("aroundexec")

  register_hook("aroundexec")
  register_hook("preexec")
  register_hook("postexec")

  register_hook("aroundexec")
  register_hook("postexec")
  register_hook("preexec")

  register_hook("postexec")
  register_hook("aroundexec")
  register_hook("preexec")

  register_hook("postexec")
  register_hook("preexec")
  register_hook("aroundexec")


  expect_output(
    result <- r$exec(req = list(), res = -1),
    paste(
      sep = "\n",
      "preexec 1",
      "preexec 4",
      "preexec 8",
      "preexec 12",
      "preexec 15",
      "preexec 17",
      "aroundexec pre 18",
      "aroundexec pre 14",
      "aroundexec pre 10",
      "aroundexec pre 7",
      "aroundexec pre 6",
      "aroundexec pre 2",
      "exec",
      "aroundexec post 2",
      "aroundexec post 6",
      "aroundexec post 7",
      "aroundexec post 10",
      "aroundexec post 14",
      "aroundexec post 18",
      "postexec 3",
      "postexec 5",
      "postexec 9",
      "postexec 11",
      "postexec 13",
      "postexec 16"
    )

  )
  expect_equal(result, expected_sum)
})
