context("Injection")

test_that("Injected arguments on req$args get passed on.", {
  r <- plumber$new(test_path("files/filter-inject.R"))

  res <- PlumberResponse$new()
  expect_equal(r$serve(make_req("GET", "/"), res)$body, jsonlite::toJSON(13))
})
