context("Injection")

test_that("Injected arguments on req$args get passed on.", {
  r <- plumber$new(test_path("files/filter-inject.R"))

  expect_equal(r$call(make_req("GET", "/"))$body, jsonlite::toJSON(13))
})
