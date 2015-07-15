test_that("JSON serializes properly", {
  l <- list(a=1, b=2, c="hi")
  val <- jsonSerializer(l, list(), PlumberResponse$new("json"), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/json")
  expect_equal(val$body, jsonlite::toJSON(l))
})

test_that("Errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  jsonSerializer(parse(text="hi"), list(), PlumberResponse$new("json"), err = errHandler)
  expect_equal(errors, 1)
})
