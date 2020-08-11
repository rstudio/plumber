context("default handlers")

test_that("404 handler sets 404", {
  res <- PlumberResponse$new()
  val <- default404Handler(list(), res)
  expect_equal(res$status, 404)
  expect_match(val$error, "404")
  expect_match(val$error, "Not Found")
})

test_that("405 handling is ok, get the right verbs", {
  pr <- plumber$new()
  sub <- plumber$new()
  sub$handle("GET", "/test", force)
  pr$mount("/barret", sub)

  expect_equal(allowed_verbs(pr, path_to_find = "/barret/test"), "GET")
  expect_null(allowed_verbs(pr, path_to_find = "/subroute/not_found"))
  expect_null(allowed_verbs(pr, path_to_find = "/barret/"))
  expect_null(allowed_verbs(pr, path_to_find = "/barret/wrong"))

  expect_false(is_405(pr, path_to_find = "/barret/test", "GET"))
  expect_true(is_405(pr, path_to_find = "/barret/test", "POST"))
  expect_false(is_405(pr, path_to_find = "/subroute/not_found"))

  pr <- plumber$new()
  sub <- plumber$new()
  sub$handle("GET", "/test", force)
  pr$mount("/", sub)

  expect_equal(allowed_verbs(pr, path_to_find = "/test"), "GET")
  expect_null(allowed_verbs(pr, path_to_find = "/subroute/not_found"))
  expect_null(allowed_verbs(pr, path_to_find = "/barret/"))
  expect_null(allowed_verbs(pr, path_to_find = "/barret/wrong"))

})

test_that("default error handler returns an object with an error property", {
  res <- PlumberResponse$new()
  capture.output(val <- defaultErrorHandler()(list(), res, "I'm an error!"))
  expect_match(val$error, "500")
  expect_match(val$error, "Internal server error")
  expect_equal(res$status, 500)
})
test_that("error handler doesn't clobber non-200 status", {
  res <- PlumberResponse$new()
  res$status <- 403
  capture.output(val <- defaultErrorHandler()(list(), res, "I'm an error!"))
  expect_match(val$error, "Internal error")
  expect_equal(res$status, 403)
})

test_that("error handler only includes message in debug mode.", {
  res <- PlumberResponse$new()
  capture.output(val <- defaultErrorHandler()(list(), res, "I'm an error!"))
  expect_null(val$message)

  res <- PlumberResponse$new()
  capture.output({
    val <- defaultErrorHandler()(
      req = list(pr = list(get_debug = function() { TRUE })),
      res,
      "I'm an error!"
    )
  })
  expect_equal(val$message, "I'm an error!")
})
