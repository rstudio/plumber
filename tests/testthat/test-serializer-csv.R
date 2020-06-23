context("CSV serializer")

test_that("CSV serializes properly", {
  skip_if_not_installed("readr")

  d <- data.frame(a=1, b=2, c="hi")
  val <- serializer_csv()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain; charset=UTF-8")
  expect_equal(val$body, readr::format_csv(d))

  d <- data.frame(a=1, b=2, c="hi", na=NA)
  val <- serializer_csv()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain; charset=UTF-8")
  expect_equal(val$body, readr::format_csv(d, na = "NA"))

  d <- data.frame(a=1, b=2, c="hi", na=NA)
  val <- serializer_csv(na = 'string')(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/plain; charset=UTF-8")
  expect_equal(val$body, readr::format_csv(d, na = 'string'))
})

test_that("Errors call error handler", {
  skip_if_not_installed("readr")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_csv()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), err = errHandler)
  expect_equal(errors, 1)
})
