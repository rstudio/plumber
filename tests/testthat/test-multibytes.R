context("multibytes source file")

test_that("support files with multibytes", {
  # on Windows, the default encoding is not UTF-8. So, plumber has to
  # tell R to use UTF-8 encoding when reading the source file.
  r <- plumber$new("files/multibytes.R")
  req <- make_req("GET", "/echo")
  res <- PlumberResponse$new()
  out <- r$serve(req, res)$body
  expect_identical(out, jsonlite::toJSON("\u4e2d\u6587\u6d88\u606f"))
  expect_equal(Encoding(out), utf8Encoding)
})
