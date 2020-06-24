context("Router modifier (@plumber tag)")

test_that("router modifier tag works correctly", {
  pr <- plumber$new(test_path("files/router-modifier.R"))
  expect_equal(class(pr$routes[[1]])[1], "PlumberEndpoint")
  expect_equal(names(pr$routes), "avatartare")
})
