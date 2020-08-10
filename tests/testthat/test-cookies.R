context("Cookies")

skip_if_no_cookie_support <- function() {
  skip_if_not_installed("sodium")
  skip_if_not_installed("base64enc")
}

test_that("cookies are parsed", {

  cookies <- parseCookies("spaced=cookie%2C%20here; another=2")
  expect_equal(names(cookies), c("spaced", "another"))
  expect_equal(cookies$spaced, "cookie, here")
  expect_equal(cookies$another, "2")

  cookies <- parseCookies("a=zxcv=asdf; missingVal=; b=qwer=ttyui")
  expect_equal(names(cookies), c("a", "missingVal", "b"))
  expect_equal(cookies$a, "zxcv=asdf")
  expect_equal(cookies$missingVal, "")
  expect_equal(cookies$b, "qwer=ttyui")

})

test_that("missing cookies are an empty list", {
  cookies <- parseCookies("")

  expect_equal(cookies, list())
})

cookieReq <- function(cookieStr) {
  req <- new.env()
  req$HTTP_COOKIE <- cookieStr
  cookieFilter(req)
  req
}

test_that("the cookies list is set", {
  req <- cookieReq("abc=123")
  expect_equal(req$cookies$abc, "123")
})

test_that("missing cookie values are empty string", {
  req <- cookieReq("abc=")
  expect_equal(req$cookies$abc, "")
})

test_that("cookies can convert to string", {
  testthat::skip_on_cran()

  expect_equal(cookieToStr("abc", 123), "abc=123")
  expect_equal(cookieToStr("complex", "string with spaces"), "complex=string%20with%20spaces")
  expect_equal(cookieToStr("complex2", "forbidden:,%/"), "complex2=forbidden%3A%2C%25%2F")
  expect_equal(cookieToStr("abc", 123, path="/somepath"), "abc=123; Path=/somepath")
  expect_equal(cookieToStr("abc", 123, http=TRUE, secure=TRUE), "abc=123; HttpOnly; Secure")
  expect_equal(cookieToStr("abc", 123, http=TRUE, secure=TRUE, sameSite="None"), "abc=123; HttpOnly; Secure; SameSite=None")

  now <- force(Sys.time())
  cookieToStr_ <- function(expiration, ...) {
    cookieToStr("abc", 123, expiration = expiration, ..., now = now)
  }
  cookie_match <- function(expirationStr, expiresSec) {
    # difftime is exclusive, so the Max-Age may be off by one on positive time diffs.
    #   Using a regex from 0 to 9 incase a slow machine is encountered
    # match from 0 to 9 seconds
    paste0("abc=123; Expires= ", expirationStr, "; Max-Age= ", expiresSec)
  }
  expect_cookie <- function(expiresSec) {
    expires <- now + expiresSec
    expyStr <- format(expires, format="%a, %e %b %Y %T", tz="GMT", usetz=TRUE)

    # When given as a number of seconds
    expect_equal(cookieToStr_(expiresSec), cookie_match(expyStr, expiresSec), label = "Raw seconds expiration cookie")

    # When given as a POSIXct
    expect_equal(cookieToStr_(expires), cookie_match(expyStr, expiresSec), label = "POSIXct expiration cookie")
  }

  # Test date in the future
  expect_cookie(9)

  # Works with a negative number of seconds
  expect_cookie(-8)
})

test_that("remove cookie string works", {
  expect_equal(
    removeCookieStr("asdf"),
    "asdf=; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
  expect_equal(
    removeCookieStr("asdf", path = "/"),
    "asdf=; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
  expect_equal(
    removeCookieStr("asdf", http = TRUE),
    "asdf=; HttpOnly; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
  expect_equal(
    removeCookieStr("asdf", secure = TRUE),
    "asdf=; Secure; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
  expect_equal(
    removeCookieStr("asdf", path = "/", http = TRUE, secure = TRUE),
    "asdf=; Path=/; HttpOnly; Secure; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
  expect_equal(
    removeCookieStr("asdf", path = "/", http = TRUE, secure = TRUE, sameSite = "None"),
    "asdf=; Path=/; HttpOnly; Secure; SameSite=None; Expires=Thu, 01 Jan 1970 00:00:00 GMT"
  )
})


test_that("asCookieKey conforms entropy", {
  skip_if_no_cookie_support()


  secretFromStr <- function(val, count) {
    rep(val, count) %>%
      paste0(collapse = "")
  }

  expect_cookie_key <- function(key) {
    expect_type(key, "raw")
    expect_length(key, 32)
  }
  expect_invalid_cookie <- function(secret) {
    expect_error({
      asCookieKey(secret)
    }, "Illegal cookie")
  }
  expect_legacy_cookie <- function(secret) {
    expect_warning({
      cookie <- asCookieKey(secret)
    }, "Legacy cookie secret")
    ret <- expect_cookie_key(cookie)
    invisible(ret)
  }

  expect_warning({
    expect_null(asCookieKey(NULL))
  }, "Cookies will not be encrypted")

  # not char
  expect_invalid_cookie(42)
  expect_invalid_cookie(sodium::random(31))
  expect_invalid_cookie(sodium::random(100))

  # legacy cookie
  # convert non hexadecimal to hexadecimal
  expect_legacy_cookie(secretFromStr("a", 63))
  expect_legacy_cookie(secretFromStr("a", 65))
  expect_legacy_cookie(secretFromStr("/", 64))

  # Used as 64 digit hex bin
  ## lower case a
  char <- secretFromStr("a", 64)
  key <- asCookieKey(char)
  expect_cookie_key(key)
  expect_equal(key, sodium::hex2bin(char))

  ## upper case a
  char <- secretFromStr("A", 64)
  key <- asCookieKey(char)
  expect_cookie_key(key)
  expect_equal(key, sodium::hex2bin(char))

  ## hex char input
  randomRaw <- sodium::random(32) %>% sodium::bin2hex()
  key <- asCookieKey(randomRaw)
  expect_cookie_key(key)
  expect_equal(sodium::bin2hex(key), randomRaw)
})


test_that("cookie encryption works", {
  skip_if_no_cookie_support()

  # check that you can't encode a NULL value
  expect_equal(encodeCookie(NULL, NULL), "")
  expect_equal(encodeCookie(NULL, asCookieKey(randomCookieKey())), "")

  xVals <- list(
    list(),
    "",
    list(a = 4, b = 3),
    rep("1234567890", 100) %>% paste0(collapse = "")
  )
  keys <- list(
    NULL, # no key
    asCookieKey(randomCookieKey()), # random key
    asCookieKey(randomCookieKey()) # different random key
  )

  for (key in keys) {
    for (x in xVals) {
      encrypted <- encodeCookie(x, key)
      encryptedStr <- cookieToStr("cookieVal", encrypted)

      encryptedParsed <- parseCookies(encryptedStr)
      maybeX <- decodeCookie(encryptedParsed$cookieVal, key)
      expect_equal(x, maybeX)
    }
  }

})

test_that("cookie encyption fails smoothly", {
  skip_if_no_cookie_support()

  x <- list(x = 4, y = 5)

  # garbage in
  garbage <- x %>%
    serialize(NULL) %>%
    sodium::hash() %>% # make "garbage"
    base64enc::base64encode()

  # garbage in, no key
  expect_error({
    decodeCookie(garbage, NULL)
  }) # error from jsonlite::parse_json()
  # garbage in, key
  expect_error({
    decodeCookie(garbage, asCookieKey(randomCookieKey()))
  }, "Could not separate")

  infoList <- list(
    # different cookies
    list(
      a = asCookieKey(randomCookieKey()),
      b = asCookieKey(randomCookieKey()),
      error = "Failed to decrypt"
    ),
    # not encrypted, try to decrypt
    list(
      a = NULL,
      b = asCookieKey(randomCookieKey()),
      error = "Could not separate"
    ),
    # encrypted, no decryption
    list(
      a = asCookieKey(randomCookieKey()),
      b = NULL
      # error from jsonlite::parse_json()
    )
  )

  for (info in infoList) {
    keyA <- info$a
    keyB <- info$b
    err <- info$error

    expect_error({
      encrypted <- encodeCookie(x, keyA)
      encryptedStr <- cookieToStr("cookieVal", encrypted)

      encryptedParsed <- parseCookies(encryptedStr)
      maybeX <- decodeCookie(encryptedParsed$cookieVal, keyB)
    }, err)
  }

})


test_that("large cookie size makes warning", {
  skip_if_no_cookie_support()

  largeObj <- rbind(iris, iris)
  encrypted <- encodeCookie(largeObj, NULL)
  expect_warning({
    cookieToStr("cookieVal", encrypted)
  }, "Cookie being saved is too large")
})
