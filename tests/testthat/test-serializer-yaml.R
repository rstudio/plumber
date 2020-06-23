context("YAML serializer")

test_that("YAML serializes properly", {
  skip_if_not_installed("yaml")

  l <- list(a=1, b=2, c="hi")
  val <- serializer_yaml()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/x-yaml")
  expect_equal(val$body, yaml::as.yaml(l))

  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_yaml()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/x-yaml")
  expect_equal(val$body, yaml::as.yaml(l))

  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_yaml(indent = 4)(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/x-yaml")
  expect_equal(val$body, yaml::as.yaml(l, indent = 4))
})

test_that("Errors call error handler", {
  skip_if_not_installed("yaml")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_yaml()(parse(text="hi"), list(), PlumberResponse$new("yaml"), err = errHandler)
  expect_equal(errors, 1)
})
