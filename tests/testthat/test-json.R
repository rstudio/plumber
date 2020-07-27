context("JSON")

test_that("safeFromJSON is safe", {
  # Valid JSON works
  a <- safeFromJSON('{"key": "value"}')
  expect_equal(a, list(key="value"))

  # File paths fail
  expect_error(safeFromJSON("/etc/passwd")) # error from jsonlite::parse_json()

  # Remote URLs fail
  expect_error(safeFromJSON("http://server.org/data.json")) # error from jsonlite::parse_json()
})
