context("shared secret")

test_that("requests with shared secrets pass, w/o fail", {
  options(`plumber.sharedSecret`="abcdefg")

  pr <- plumber$new()
  pr$handle("GET", "/", function(){ 123 })

  # No shared secret
  req <- make_req("GET", "/")
  res <- PlumberResponse$new()
  capture.output(pr$route(req, res))
  expect_equal(res$status, 400)

  # Set shared secret
  assign("HTTP_PLUMBER_SHARED_SECRET", "abcdefg", envir=req)
  res <- PlumberResponse$new()
  pr$route(req, res)
  expect_equal(res$status, 200)

  options(`plumber.sharedSecret`=NULL)
})
