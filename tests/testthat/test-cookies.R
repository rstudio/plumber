context("Cookies")

test_that("cookies are parsed", {
  co <- parseCookies("spaced=cookie%20here; another=2")

  expect_equal(co$spaced, "cookie here")
  expect_equal(co$another, "2")
})

test_that("missing cookies are an empty list", {
  co <- parseCookies("")

  expect_equal(co, list())
})

test_that("the cookies list is set", {
  req <- new.env()
  req$HTTP_COOKIE <- "abc=123"
  cookieFilter(req)

  expect_equal(req$cookies$abc, "123")
})

test_that("missing cookie values are empty string", {
  req <- new.env()
  req$HTTP_COOKIE <- "abc="
  cookieFilter(req)

  expect_equal(req$cookies$abc, "")
})

test_that("cookies can convert to string", {
  testthat::skip_on_cran()

  expect_equal(cookieToStr("abc", 123), "abc=123")
  expect_equal(cookieToStr("complex", "string with spaces"), "complex=string%20with%20spaces")
  expect_equal(cookieToStr("abc", 123, path="/somepath"), "abc=123; Path=/somepath")
  expect_equal(cookieToStr("abc", 123, http=TRUE, secure=TRUE), "abc=123; HttpOnly; Secure")

  # Test date in the future
  expiresSec <- 10
  expires <- Sys.time() + expiresSec
  expyStr <- format(expires, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)
  # TODO: this test is vulnerable to Sys.time() crossing over a second boundary in between the
  # line above and below.
  # When given as a number of seconds
  expect_equal(cookieToStr("abc", 123, expiration=expiresSec),
               paste0("abc=123; Expires= ", expyStr, "; Max-Age= ", expiresSec))
  # When given as a POSIXct
  # difftime is exclusive, so the Max-Age may be off by one on positive time diffs.
  expect_equal(cookieToStr("abc", 123, expiration=expires),
               paste0("abc=123; Expires= ", expyStr, "; Max-Age= ", expiresSec-1))

  # Works with a negative number of seconds
  expiresSec <- -10
  expires <- Sys.time() + expiresSec
  expyStr <- format(expires, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)
  # TODO: this test is vulnerable to Sys.time() crossing over a second boundary in between the
  # line above and below.
  # When given as a number of seconds
  expect_equal(cookieToStr("abc", 123, expiration=expiresSec),
               paste0("abc=123; Expires= ", expyStr, "; Max-Age= ", expiresSec))
  # When given as a POSIXct
  expect_equal(cookieToStr("abc", 123, expiration=expires),
               paste0("abc=123; Expires= ", expyStr, "; Max-Age= ", expiresSec))
})
