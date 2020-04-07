context("CSV serializer")

test_that("CSV serializes properly", {
  d <- data.frame(a=1, b=2, c="hi")
  val <- serializer_csv()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain")
  expect_equal(val$body, readr::format_csv(d))

  d <- data.frame(a=1, b=2, c="hi", na=NA)
  val <- serializer_csv()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain")
  expect_equal(val$body, readr::format_csv(d, na = "NA"))

  d <- data.frame(a=1, b=2, c="hi", na=NA)
  val <- serializer_csv(na = 'test-na')(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain")
  expect_equal(val$body, readr::format_csv(d, na = 'test-na'))
})

test_that("Errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_csv()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), err = errHandler)
  expect_equal(errors, 1)
})
