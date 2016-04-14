make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Images are properly rendered", {
  r <- plumber$new("files/image.R")
  resp <- r$serve(make_req("GET", "/png"), PlumberResponse$new())

  expect_gt(length(resp$body), 1000) # This changes based on R ver/OS, may not be useful.

  resp <- r$serve(make_req("GET", "/jpeg"), PlumberResponse$new())
  expect_gt(length(resp$body), 1000) # This changes based on R ver/OS, may not be useful.
})
