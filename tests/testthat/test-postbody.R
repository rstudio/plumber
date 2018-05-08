context("POST body")

test_that("JSON is consumed on POST", {
  expect_equal(parseBody('{"a":"1"}'), list(a = "1"))
})

test_that("Query strings on post are handled correctly", {
  expect_equivalent(parseBody("a="), list()) # It's technically a named list()
  expect_equal(parseBody("a=1&b=&c&d=1"), list(a="1", d="1"))
})

test_that("Able to handle UTF-8", {
  expect_equal(parseBody('{"text":"Ã©lise"}', 'UTF-8')$text, "Ã©lise")
})
