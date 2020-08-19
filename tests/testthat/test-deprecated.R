context("Deprecated")

test_that("addEndpoint continues to work", {
  pr <- Plumber$new()
  expect_warning(pr$addEndpoint("GET", "/", function(){ 123 }))
  expect_error(expect_warning(pr$addEndpoint("GET", "/", function(){ 123 }, comments="break")))

  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_equal(val, 123)
})

test_that("addFilter continues to work", {
  pr <- Plumber$new()
  expect_warning(pr$addFilter("f1", function(req){ req$filtered <- TRUE }))
  pr$handle("GET", "/", function(req){ req$filtered })

  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_true(val)
})

test_that("addGlobalProcessor continues to work", {
  pr <- Plumber$new()
  expect_warning(pr$addGlobalProcessor(session_cookie("secret", "cookieName")))
})

test_that("addAssets continues to work", {
  pr <- Plumber$new()
  expect_warning(pr$addAssets(test_path("./files/static"), "/public"))
  res <- PlumberResponse$new()
  val <- pr$route(make_req("GET", "/public/test.txt"), res)
  expect_true(inherits(val, "PlumberResponse"))
})


test_that("getCharacterSet continues to work", {
  expect_equal(
    lifecycle::expect_deprecated(getCharacterSet(contentType = "foo")),
    "UTF-8"
  )
})


test_that("sessionCookie continues to work", {
  key <- random_cookie_key()
  cookie_hooks_old <- lifecycle::expect_deprecated(sessionCookie(key))
  cookie_hooks_new <- expect_silent(session_cookie(key))

  expect_equal(names(cookie_hooks_old), names(cookie_hooks_new))
})

test_that("hookable throws deprecated warning", {
  expect_warning(hookable$new(), "Hookable")
})
test_that("plumber throws deprecated warning", {
  expect_warning(plumber$new(), "Plumber")
})


test_that("Digital Ocean functions throw errors", {
  skip_on_cran()

  # Do not test if plumberDeploy is installed, as real functions will executed
  skip_if(plumberDeploy_is_installed())

  expect_error(do_provision(), class = "lifecycle_error_deprecated")
  expect_error(do_configure_https(), class = "lifecycle_error_deprecated")
  expect_error(do_deploy_api(), class = "lifecycle_error_deprecated")
  expect_error(do_forward(), class = "lifecycle_error_deprecated")
  expect_error(do_remove_api(), class = "lifecycle_error_deprecated")
  expect_error(do_remove_forward(), class = "lifecycle_error_deprecated")
})
