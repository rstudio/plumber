context("POST body")

test_that("JSON is consumed on POST", {
  expect_equal(parseBody('{"a":"1"}'), list(a = "1"))
})

test_that("Query strings on post are handled correctly", {
  expect_equivalent(parseBody("a="), list()) # It's technically a named list()
  expect_equal(parseBody("a=1&b=&c&d=1"), list(a="1", d="1"))
})

test_that("Able to handle UTF-8", {
  expect_equal(parseBody('{"text":"Ã©lise"}', content_type = "application/json; charset=UTF-8")$text, "Ã©lise")
})

#charset moved to part parsing
test_that("filter passes on content-type", {
  content_type_passed <- ""
  req <- list(
    .internal = list(postBodyHandled = FALSE),
    rook.input = list(
      read = function() {
        called <- TRUE
        return("this is a body")
      }
    ),
    HTTP_CONTENT_TYPE = "text/html; charset=testset",
    args = c()
  )
  with_mock(
    parseBody = function(body, content_type = "unknown") {
      print(content_type)
      body
    },
    expect_output(postBodyFilter(req), "text/html; charset=testset"),
    .env = "plumber"
  )
})
