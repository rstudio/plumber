context("Options")

test_that("Options set and get", {
  option_value <- getOption("plumber.postBody")
  optionsPlumber(postBody = FALSE)
  expect_false(getOption("plumber.postBody"))
  expect_false(optionsPlumber()$plumber.postBody)
  optionsPlumber(postBody = NULL)
  expect_null(getOption("plumber.postBody"))
  options(plumber.postBody = option_value)
})
