make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Images are properly rendered", {
  r <- RapierRouter$new("files/image.R")
  resp <- r$serve(make_req("GET", "/png"), RapierResponse$new())
  expect_equal(nchar(resp$body[1]), 17396) # This may change with changes to base graphics that slightly alter the plot format. But we'll start here.

  resp <- r$serve(make_req("GET", "/jpeg"), RapierResponse$new())
  expect_equal(nchar(resp$body[1]), 18616) # This may change with changes to base graphics that slightly alter the plot format. But we'll start here.
})
