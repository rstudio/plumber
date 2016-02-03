make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Routing to errors and 404s works", {
  r <- plumber$new("files/warn.R")

  res <- plumber:::PlumberResponse$new("json")

  expect_equal(options("warn")[[1]], 0)
  expect_warning(r$route(make_req("GET", "/warning"), res), "this is a warning")
  expect_equal(res$status, 1)
  expect_equal(options("warn")[[1]], 0)
})
