context("feather serializer")

test_that("feather serializes properly", {
  skip_if_not_installed("feather")

  d <- data.frame(a=1, b=2, c="hi")
  val <- serializer_feather()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/feather; charset=UTF-8")

  # can test  by doing a full round trip if we believe the parser works via `test-parse-body.R`
  parsed <- parse_body(val$body, "application/feather", make_parser("feather"))
  # convert from feather tibble to data.frame
  parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  attr(parsed, "spec") <- NULL

  expect_equal(parsed, d)
})

test_that("Errors call error handler", {
  skip_if_not_installed("feather")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_feather()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), errorHandler = errHandler)
  expect_equal(errors, 1)
})
