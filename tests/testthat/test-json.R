context("JSON")

test_that("safeFromJSON is safe", {
  # Valid JSON works
  a <- safeFromJSON('{"key": "value"}')
  expect_equal(a, list(key="value"))

  # File paths fail
  expect_error(safeFromJSON("/etc/passwd"), "not a valid JSON string")

  # Remote URLs fail
  expect_error(safeFromJSON("http://server.org/data.json"), "not a valid JSON string")
})
