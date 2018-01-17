context("Verb enumeration")

test_that("enumerate returns all on 'use'", {
  expect_equal(enumerateVerbs("use"), c("GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS", "PATCH"))
})

test_that("regular verbs return themselves", {
  expect_equal(enumerateVerbs("get"), "GET")
  expect_equal(enumerateVerbs("post"), "POST")
})
