context("Router modifier (@plumber tag)")

test_that("router modifier works", {
  pr <- pr(test_path("files/router-modifier.R"))
  expect_equal(class(pr$routes[[1]])[1], "PlumberEndpoint")
  expect_equal(names(pr$routes), "avatartare")
})

test_that("$run() causes error", {
  expect_error(
    pr(test_path("files/router-modifier-run.R")),
    "method should not be called while")
})


test_that("new routers can not be returned", {
  expect_error(
    pr(test_path("files/router-modifier-new.R")),
    "not the same as the one provided")
})
