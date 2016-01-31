make_req <- function(verb, path, cookie){
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
  r <- plumber$new()

  expr <- expression(function(req, res){ req$session <- list(abc=123); TRUE })

  r$addEndpoint("GET", "/", expr)

  sc <- sessionCookie(name="plcook")

  r$addGlobalProcessor(sc)

  res <- plumber:::PlumberResponse$new()
  r$serve(make_req("GET", "/"), res)

  expect_equal(res$headers[["Set-Cookie"]], 'plcook={"abc":[123]}')
})

test_that("cookies are read", {
  r <- plumber$new()

  expr <- expression(function(req, res){ req$session$abc })

  r$addEndpoint("GET", "/", expr)

  sc <- sessionCookie(name="plcook")

  r$addGlobalProcessor(sc)

  res <- plumber:::PlumberResponse$new()
  r$serve(make_req("GET", "/", 'plcook={"abc":[123]}'), res)

  expect_equal(res$body, jsonlite::toJSON(123))
})
