context("Options")

test_that("Options set and get", {
  option_value <- getOption("plumber.postBody")
  setPlumberOptions(postBody = FALSE)
  expect_false(getOption("plumber.postBody"))
  expect_false(getPlumberOptions()$plumber.postBody)
  setPlumberOptions(postBody = NULL)
  expect_null(getOption("plumber.postBody"))
  options(plumber.postBody = option_value)
})
