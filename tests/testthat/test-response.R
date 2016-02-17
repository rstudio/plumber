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

test_that("can set multiple same-named headers", {
  res <- PlumberResponse$new()
  res$setHeader("head", "test")
  res$setHeader("head", "another")

  test <- FALSE
  another <- FALSE

  pres <- res$toResponse()
  for (i in 1:length(pres$headers)){
    n <- names(pres$headers)[i]
    if (n == "head"){
      if (pres$headers[[i]] == "test"){
        test <- TRUE
      } else if (pres$headers[[i]] == "another"){
        another <- TRUE
      }
    }
  }

  expect_true(test)
  expect_true(another)
})

test_that("doesn't overwrite CORS", {
  res <- PlumberResponse$new()
  res$setHeader("Access-Control-Allow-Origin", "originhere")
  head <- res$toResponse()$headers
  expect_equal(head[["Access-Control-Allow-Origin"]], "originhere")
})
