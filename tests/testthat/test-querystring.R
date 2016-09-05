test_that("query strings are properly parsed", {
  expect_equal(parseQS("?a=1"), list(a="1"))
  expect_equal(parseQS("b=2"), list(b="2"))
  expect_equal(parseQS("a=1&b=2&c=url%20encoded"), list(a="1", b="2", c="url encoded"))
})

test_that("null an empty strings return empty list", {
  expect_equal(parseQS(NULL), list())
  expect_equal(parseQS(""), list())
})

test_that("incomplete query strings are ignored", {
  expect_equivalent(parseQS("a="), list()) # It's technically a named list()
  expect_equal(parseQS("a=1&b=&c&d=1"), list(a="1", d="1"))
})
