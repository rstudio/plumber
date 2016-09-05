test_that("JSON is consumed on POST", {
  expect_equal(parseBody('{"a":"1"}'), list(a = "1"))
})
