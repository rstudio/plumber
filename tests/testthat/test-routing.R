make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Routing to errors and 404s works", {
  r <- plumber$new("files/router.R")
  errors <- 0
  notFounds <- 0

  errRes <- list(a=1)
  notFoundRes <- list(b=2)

  r$setErrorHandler(function(req, res, err){ errors <<- errors + 1; errRes })
  r$set404Handler(function(req, res){ notFounds <<- notFounds + 1; notFoundRes })

  res <- PlumberResponse$new("json")

  expect_equal(r$route(make_req("GET", "/"), res), "first")
  expect_equal(r$route(make_req("GET", "/abc"), res), "abc get")
  expect_equal(r$route(make_req("GET", "/dog"), res), "dog get")
  expect_equal(r$route(make_req("POST", "/dog"), res), "dog use")

  expect_equal(errors, 0)
  expect_equal(notFounds, 0)

  nf <- r$route(make_req("GET", "/something-crazy"), res)
  expect_equal(res$serializer, "json")
  expect_equal(nf, notFoundRes)
  expect_equal(notFounds, 1)

  er <- r$route(make_req("GET", "/error"), res)
  expect_equal(res$serializer, "json")
  expect_equal(er, errRes)
  expect_equal(errors, 1)
})
