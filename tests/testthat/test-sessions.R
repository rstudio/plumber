context("Sessions")

skip_if_no_cookie_support <- function() {
  skip_if_not_installed("sodium")
  skip_if_not_installed("base64enc")
}


make_req_cookie <- function(verb, path, cookie) {
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function() { "" },
                         rewind = function() {},
                         read = function() { charToRaw("") })
  if (!missing(cookie)){
    req$HTTP_COOKIE <- cookie
  }
  req
}

test_that("sessionCookie throws missing key", {
  expect_error(
    sessionCookie(),
    "You must define an encryption key"
  )
})

test_that("cookies are set", {
  skip_if_no_cookie_support()

  r <- plumber$new()
  expr <- expression(function(req, res){ req$session <- list(abc = 1234); TRUE })

  r$handle("GET", "/", expr)

  key <- randomCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )

  r$registerHooks(sc)

  res <- PlumberResponse$new()
  r$serve(make_req_cookie("GET", "/"), res)

  cook <- res$headers[["Set-Cookie"]]
  expect_match(cook, "^plcook")
  cook <- parseCookies(cook)$plcook
  expect_equal(decodeCookie(cook, asCookieKey(key)), list(abc = 1234))
})

test_that("cookies are unset", {
  skip_if_no_cookie_support()

  r <- plumber$new()
  exprRemoveSession <- expression(function(req, res){ req$session <- NULL; TRUE })

  r$handle("GET", "/", exprRemoveSession)

  key <- randomCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )

  r$registerHooks(sc)

  res <- PlumberResponse$new()
  r$serve(
    make_req_cookie(
      "GET", "/",
      # start with a session cookie
      paste0("plcook=", encodeCookie(list(abc = 1234), asCookieKey(key)))
    ),
    res
  )

  cook <- res$headers[["Set-Cookie"]]
  expect_match(cook, "^plcook=;")
  expect_true(grepl("Thu, 01 Jan 1970", cook, fixed = TRUE))
})

test_that("cookies are read", {
  skip_if_no_cookie_support()

  r <- plumber$new()

  expr <- expression(function(req, res){ req$session$abc })

  r$handle("GET", "/", expr)

  key <- randomCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )
  r$registerHooks(sc)


  # Create the request with an encrypted cookie
  res <- PlumberResponse$new()
  r$serve(
    make_req_cookie(
      "GET", "/",
      # start with a session cookie
      paste0("plcook=", encodeCookie(list(abc = 1234), asCookieKey(key)))
    ),
    res
  )

  expect_equal(res$body, jsonlite::toJSON(1234))
})

test_that("invalid cookies/JSON are handled", {
  skip_if_no_cookie_support()

  r <- plumber$new()

  expr <- expression(function(req, res){ ifelse(is.null(req$session), "no session", req$session) })

  r$handle("GET", "/", expr)

  key <- randomCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )
  r$registerHooks(sc)

  res <- PlumberResponse$new()

  badKey <- randomCookieKey()
  x <- list(abc = 1234)
  encodedX <- encodeCookie(x, asCookieKey(badKey))
  expect_silent({
    r$serve(
      make_req_cookie(
        "GET", "/",
        paste0('plcook=', encodedX)
      ),
      res
    )
  })
  expect_equal(res$body, jsonlite::toJSON("no session"))
})

test_that("cookie attributes are set", {
  skip_if_no_cookie_support()

  r <- plumber$new()
  expr <- expression(function(req, res){ req$session <- list(abc = 1234); TRUE })

  r$handle("GET", "/", expr)

  key <- randomCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook",
    expiration = 10,
    http = TRUE,
    secure = TRUE,
    sameSite = "None"
  )

  r$registerHooks(sc)

  res <- PlumberResponse$new()
  r$serve(make_req_cookie("GET", "/"), res)

  cook <- res$headers[["Set-Cookie"]]
  expect_match(cook, "^plcook")
  expect_match(cook, "Expires=[^;]+(?:;|$)")
  expect_match(cook, "Max-Age=\\s*\\d+(?:;|$)")
  expect_match(cook, "HttpOnly(?:;|$)")
  expect_match(cook, "Secure(?:;|$)")
  expect_match(cook, "SameSite=None(?:;|$)")
  cook <- parseCookies(cook)$plcook
  expect_equal(decodeCookie(cook, asCookieKey(key)), list(abc = 1234))
})
