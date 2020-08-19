context("Router modifier (@plumber tag)")

test_that("router modifier works, run does nothing", {
  expect_error(
    pr(test_path("files/router-modifier-run.R")),
    "method should not be called while")
  pr <- pr(test_path("files/router-modifier.R"))
  expect_equal(class(pr$routes[[1]])[1], "PlumberEndpoint")
  expect_equal(names(pr$routes), "avatartare")
})
