context("test-query-with-multibytes")

test_that("Support multi-bytes queries", {
  r <- plumber$new(test_path("files/query-with-multibytes.R"))
  res <- PlumberResponse$new()

  req <- make_req("GET", "/msg", "?param1=%E4%B8%AD%E6%96%87&param2=%E4%BD%A0%E5%A5%BD")
  out <- r$serve(req, res)$body
  expect_equal(Encoding(out), "UTF-8")
  expect_identical(charToRaw(out), charToRaw(jsonlite::toJSON("\u4e2d\u6587-\u4f60\u597d")))

  req <- make_req("POST", "/msg", "?param1=%E4%B8%AD%E6%96%87&param2=%E4%BD%A0%E5%A5%BD")
  out <- r$serve(req, res)$body
  expect_equal(Encoding(out), "UTF-8")
  expect_identical(charToRaw(out), charToRaw(jsonlite::toJSON("\u4e2d\u6587-\u4f60\u597d")))
})
