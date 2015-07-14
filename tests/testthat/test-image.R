make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Images are properly rendered", {
  r <- PlumbrRouter$new("files/image.R")
  resp <- r$serve(make_req("GET", "/png"), PlumbrResponse$new())

  expect_equal(length(resp$body), 13044) # This may change with changes to base graphics that slightly alter the plot format. But we'll start here.

  resp <- r$serve(make_req("GET", "/jpeg"), PlumbrResponse$new())
  expect_equal(length(resp$body), 13958) # This may change with changes to base graphics that slightly alter the plot format. But we'll start here.
})
