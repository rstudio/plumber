context("JSON serializer")

test_that("JSON serializes properly", {
  l <- list(a=1, b=2, c="hi")
  val <- serializer_json()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l))

  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_json()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l, na = 'null'))

  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_json(na = 'string')(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l, na = 'string'))
})

test_that("Errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_json()(parse(text="hi"), list(), PlumberResponse$new("json"), err = errHandler)
  expect_equal(errors, 1)
})

context("Unboxed JSON serializer")

test_that("Unboxed JSON serializes properly", {
  l <- list(a=1, b=2, c="hi")
  val <- serializer_unboxed_json()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l, auto_unbox = TRUE))


  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_unboxed_json()(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l, auto_unbox = TRUE, na = 'null'))

  l <- list(a=1, b=2, c="hi", na=NA)
  val <- serializer_unboxed_json(na = 'string')(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l,  auto_unbox = TRUE, na = 'string'))
})

test_that("Unboxed JSON errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_unboxed_json()(parse(text="hi"), list(), PlumberResponse$new("json"), err = errHandler)
  expect_equal(errors, 1)
})
