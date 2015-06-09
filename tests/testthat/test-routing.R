make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Routing to errors and 404s works", {
  r <- RapierRouter$new("files/router.R")
  errors <- 0
  notFounds <- 0
  r$setErrorHandler(function(req, res, err){ errors <<- errors + 1 })
  r$set404Handler(function(req, res){ notFounds <<- notFounds + 1 })

  res <- list()

  expect_equal(r$route(make_req("GET", "/"), res)$value, "first")
  expect_equal(r$route(make_req("GET", "/abc"), res)$value, "abc get")
  expect_equal(r$route(make_req("GET", "/dog"), res)$value, "dog get")
  expect_equal(r$route(make_req("POST", "/dog"), res)$value, "dog use")

  expect_equal(errors, 0)
  expect_equal(notFounds, 0)

  r$route(make_req("GET", "/something-crazy"), res)
  expect_equal(notFounds, 1)

  r$route(make_req("GET", "/error"), res)
  expect_equal(errors, 1)
})
