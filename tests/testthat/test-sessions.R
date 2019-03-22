context("Sessions")

skip_if_no_cookie_support <- function() {
  skip_if_not_installed("sodium")
  skip_if_not_installed("base64enc")
}


make_req_cookie <- function(verb, path, cookie){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  if (!missing(cookie)){
    req$HTTP_COOKIE <- cookie
  }
  req
}

test_that("cookies are set", {
  skip_if_no_cookie_support()

  r <- plumber$new()
  expr <- expression(function(req, res){ req$session <- list(abc = 1234); TRUE })

  r$handle("GET", "/", expr)

  key <- rep("mysecret", 10) %>% paste0(collapse = "") %>% asCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )

  r$registerHooks(sc)

  res <- PlumberResponse$new()
  r$serve(make_req_cookie("GET", "/"), res)

  cook <- res$headers[["Set-Cookie"]]
  expect_match(cook, "^plcook")
  cook <- gsub("^plcook=", "", cook, perl = TRUE)
  expect_equal(decodeCookie(cook, key), list(abc = 1234))
})

test_that("cookies are unset", {
  skip_if_no_cookie_support()

  r <- plumber$new()
  exprRemoveSession <- expression(function(req, res){ req$session <- NULL; TRUE })

  r$handle("GET", "/", exprRemoveSession)

  key <- rep("mysecret", 10) %>% paste0(collapse = "") %>% asCookieKey()
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
      paste0("plcook=", encodeCookie(list(abc = 1234), key))
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

  key <- rep("mysecret", 10) %>% paste0(collapse = "") %>% asCookieKey()
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
      paste0("plcook=", encodeCookie(list(abc = 1234), key))
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

  key <- rep("mysecret", 10) %>% paste0(collapse = "") %>% asCookieKey()
  sc <- sessionCookie(
    key,
    name = "plcook"
  )
  r$registerHooks(sc)

  res <- PlumberResponse$new()

  badKey <- randomCookieKey() %>% asCookieKey()
  x <- list(abc = 1234)
  encodedX <- encodeCookie(x, badKey)
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
