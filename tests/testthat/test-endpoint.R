test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(){ a }")

  r <- RapierEndpoint$new('verb', 'path', foo, env, "a", 1:2)
  expect_equal(r$exec(), 5)
})

test_that("Missing lines are ok", {
  RapierEndpoint$new('verb', 'path', { 1 }, environment())
})

test_that("Endpoints are exec'able with named arguments.", {
  foo <- parse(text="foo <- function(x){ x + 1 }")
  r <- RapierEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(x=3), 4)
})

test_that("Unnamed arguments error", {
  foo <- parse(text="foo <- function(){ 1 }")
  r <- RapierEndpoint$new('verb', 'path', foo, environment())
  expect_error(r$exec(3))

  foo <- parse(text="foo <- function(x, ...){ x + 1 }")
  r <- RapierEndpoint$new('verb', 'path', foo, environment())
  expect_error(r$exec(x=1, 3))
})

test_that("Ellipses allow any named args through", {
  foo <- parse(text="function(...){ sum(unlist(list(...))) }")
  r <- RapierEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(a=1, b=2, c=3), 6)

  foo <- parse(text="function(...){ list(...) }")
  r <- RapierEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(a="aa", b="ba"), list(a="aa", b="ba"))
})
