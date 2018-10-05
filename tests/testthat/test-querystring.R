context("query strings")

test_that("query strings are properly parsed", {
  expect_equal(parseQS("?a=1"), list(a="1"))
  expect_equal(parseQS("b=2"), list(b="2"))
  expect_equal(parseQS("a=1&b=2&c=url%20encoded"), list(a="1", b="2", c="url encoded"))
})

test_that("special characters in query strings are handled properly", {
  expect_equal(parseQS("?a=1+.#"), list(a="1+.#"))
  expect_equal(parseQS("?a=a%20b"), list(a="a b"))
})

test_that("null an empty strings return empty list", {
  expect_equal(parseQS(NULL), list())
  expect_equal(parseQS(""), list())
})

test_that("incomplete query strings are ignored", {
  expect_equivalent(parseQS("a="), list()) # It's technically a named list()
  expect_equal(parseQS("a=1&b=&c&d=1"), list(a="1", d="1"))
})

test_that("query strings with duplicates are made into vectors", {
  expect_equal(parseQS("a=1&a=2&a=3&a=4"), list(a=c("1", "2", "3", "4")))
})

test_that("parseQS() will mark UTF-8 explicitly", {
  out <- parseQS("\u53c2\u65701=\u4e2d\u6587")
  expect_identical(
    charToRaw(names(out)),
    as.raw(c(0xe5, 0x8f, 0x82, 0xe6, 0x95, 0xb0, 0x31))
  )
  expect_equal(Encoding(names(out)), "UTF-8")
  expect_identical(
    charToRaw(out[[1L]]),
    as.raw(c(0xe4, 0xb8, 0xad, 0xe6, 0x96, 0x87))
  )
  expect_equal(Encoding(out[[1L]]), "UTF-8")
})
