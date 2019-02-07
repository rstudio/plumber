context("Responses")

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

test_that("http_date_string() returns the same result as in Locale C", {
  english_time <- function(x) {
    old_lc_time <- Sys.getlocale("LC_TIME")
    Sys.setlocale("LC_TIME", "C")
    on.exit(Sys.setlocale("LC_TIME", old_lc_time), add = TRUE)
    format(x, "%a, %d %b %Y %X %Z", tz = "GMT")
  }
  x <- as.POSIXct("2018-01-01 01:00:00", tz = "Asia/Shanghai")
  expect_equal(http_date_string(x), english_time(x))
  # multiple values
  x_all_months <- sprintf("2018-%02d-03 12:00:00", 1:12)
  x_all_weeks <- sprintf("2018-01-%02d 12:00:00", 1:7)
  x <- as.POSIXct(c(x_all_months, x_all_weeks), tz = "Asia/Shanghai")
  expect_equal(http_date_string(x), english_time(x))
})
