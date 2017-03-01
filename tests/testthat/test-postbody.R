context("POST body")

test_that("JSON is consumed on POST", {
  expect_equal(parseBody('{"a":"1"}'), list(a = "1"))
})

test_that("Query strings on post are handled correctly", {
  expect_equivalent(parseBody("a="), list()) # It's technically a named list()
  expect_equal(parseBody("a=1&b=&c&d=1"), list(a = "1", d = "1"))
})

test_that("Multipart binary is consumed on POST", {
# TODO: I'm not sure how to read the file in such a way that it can be used as a
# multipart upload. I expected that copying the rawToChar(req$input.rook$read())
# output would do the trick, but it did not.
})
