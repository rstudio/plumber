context("errorHandler")

test_that("errorHandler works", {
  res <- PlumberResponse$new("")

  r <- plumber$new(test_path("files/errorhandler.R"))
  expect_error(r$serve(make_req("GET", "/fail"), res),
               regexp = "Caught")
})
