make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Injected arguments on req$args get passed on.", {
  r <- PlumbrRouter$new("files/filter-inject.R")

  res <- PlumbrResponse$new()
  expect_equal(r$serve(make_req("GET", "/"), res)$body, jsonlite::toJSON(13))
})
