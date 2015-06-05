test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(x){ x + a }")

  r <- RapierEndpoint$new('verb', 'path', foo, env, "a", 1:2)
  expect_equal(r$exec()(4), 9)
})

test_that("Missing lines are ok", {
  RapierEndpoint$new('verb', 'path', { 1 }, environment())
})
