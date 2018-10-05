context("test-query-with-multibytes")

test_that("Support multi-bytes queries", {
  r <- plumber$new("files/query-with-multibytes.R")
  res <- PlumberResponse$new()

  req <- make_req("GET", "/msg", "\u53c2\u65701=\u4e2d\u6587&\u53c2\u65702=\u4f60\u597d")
  out <- r$serve(req, res)$body
  expect_identical(out, jsonlite::toJSON("\u4e2d\u6587-\u4f60\u597d"))

  req <- make_req("POST", "/msg", "\u53c2\u65701=\u4e2d\u6587&\u53c2\u65702=\u4f60\u597d")
  out <- r$serve(req, res)$body
  expect_identical(out, jsonlite::toJSON("\u4e2d\u6587-\u4f60\u597d"))
})
