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

test_that("cookies can convert to string", {
  expect_equal(cookieListToStr(list(abc=123)), "abc=123")
  expect_equal(cookieListToStr(list(abc=123, def=456)), "abc=123; def=456")
  expect_equal(cookieListToStr(list(complex="string with spaces")), "complex=string%20with%20spaces")
  expect_equal(cookieListToStr(list()), "")
})


