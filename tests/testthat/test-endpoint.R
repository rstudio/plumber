test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(x){ x + a }")

  r <- RapierEndpoint$new('verb', 'uri', foo, env, "a", "ep", 1:2)
  expect_equal(r$exec(4), 9)
})

test_that("Missing lines are ok", {
  RapierEndpoint$new('verb', 'uri', { 1 }, environment())
})
