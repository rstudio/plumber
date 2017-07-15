context("HTML serializer")

test_that("HTML serializes properly", {
  v <- "<html><h1>Hi!</h1></html>"
  val <- htmlSerializer()(v, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "text/html; charset=utf-8")
  expect_equal(val$body, v)
})

test_that("Errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  htmlSerializer()(parse(stop("I crash")), list(), PlumberResponse$new("json"), err = errHandler)
  expect_equal(errors, 1)
})
