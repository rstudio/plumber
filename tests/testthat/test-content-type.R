test_that("contentType serializes properly", {
  l <- list(a=1, b=2, c="hi")
  val <- contentTypeSerializer("somethinghere")(l, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "somethinghere")
  expect_equal(val$body, l)
})

test_that("empty contentType errors", {
  expect_error(contentTypeSerializer())
})

test_that("contentType works in files", {

  make_req <- function(verb, path){
    req <- new.env()
    req$REQUEST_METHOD <- toupper(verb)
    req$PATH_INFO <- path
    req$rook.input <- list(read_lines = function(){ "" })
    req
  }
  res <- PlumberResponse$new()

  r <- plumber$new("files/content-type.R")
  val <- r$serve(make_req("GET", "/"), res)
  expect_equal(val$headers$`Content-Type`, "text/plain")
})
