test_that("response properly sets basic cookies", {
  res <- PlumberResponse$new()
  res$setCookie("abc", "two words")
  head <- res$toResponse()$headers
  expect_equal(head[["Set-Cookie"]], "abc=two%20words")
})

test_that("response sets non-char cookies", {
  res <- PlumberResponse$new()
  res$setCookie("abc", 123)
  head <- res$toResponse()$headers
  expect_equal(head[["Set-Cookie"]], "abc=123")
})

test_that("doesn't overwrite CORS", {
  res <- PlumberResponse$new()
  res$setHeader("Access-Control-Allow-Origin", "originhere")
  head <- res$toResponse()$headers
  expect_equal(head[["Access-Control-Allow-Origin"]], "originhere")
})
