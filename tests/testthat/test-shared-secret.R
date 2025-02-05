context("shared secret")

test_that("requests with shared secrets pass, w/o fail", {
  options(`plumber.sharedSecret`="abcdefg")

  pr <- pr() %>% pr_set_debug(FALSE)
  pr$handle("GET", "/", function(){ 123 })
  req <- make_req("GET", "/", pr = pr)

  # No shared secret
  res <- PlumberResponse$new()
  output <- pr$route(req, res)
  expect_equal(res$status, 400)
  expect_equal(output, list(error = "400 - Bad request"))

  # When debugging, we get additional details in the error.
  pr$setDebug(TRUE)
  res <- PlumberResponse$new()
  output <- pr$route(req, res)
  expect_equal(res$status, 400)
  expect_equal(output, list(
    error = "400 - Bad request",
    message = "Shared secret mismatch"))
  pr$setDebug(FALSE)

  # Set shared secret
  assign("HTTP_PLUMBER_SHARED_SECRET", "abcdefg", envir=req)
  res <- PlumberResponse$new()
  pr$route(req, res)
  expect_equal(res$status, 200)

  options(`plumber.sharedSecret`=NULL)
})
