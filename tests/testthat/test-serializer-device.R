context("device serializer")

test_that("graphics device promise domains must have a device", {
  expect_error(
    # send in a value that is returned for a null device
    createGraphicsDevicePromiseDomain(which = c(`null device` = 1L)),
    "was called without opening a device"
  )
})

test_that("you should not call `dev_set()` with a null device", {

  expect_warning(
    # send in a value that is returned for a null device
    dev_set(c(`null device` = 1L)),
    "null device"
  )
})






# Only test on CI
skip_on_cran()

expect_device_output <- function(name, content_type, capability_type = name) {

  if (!is.null(capability_type)) {
    if (!capabilities(capability_type)) {
      testthat::skip(paste0("Graphics device type not supported: ", name))
    }
  }

  ep <- NULL
  pr <- pr()

  evaluateBlock(
    srcref = 3, # which evaluates to line 2
    file = c("#' @get /test", paste0("#' @serializer ", name, " list()")),
    expr = function() {
      plot(1:10)
    },
    envir = new.env(parent=globalenv()),
    addEndpoint = function(a, b, ...) { pr$handle(endpoint = a) },
    addFilter = as.null,
    pr = pr
  )

  ret <- pr$call(make_req("GET", "/test"))

  expect_equal(ret$status, 200)
  expect_equal(ret$headers$`Content-Type`, content_type)
  expect_true(is.raw(ret$body))
  expect_gt(length(ret$body), 1000)
}



test_that("jpeg produces an image", {
  expect_device_output("jpeg", "image/jpeg")
})
test_that("png produces an image", {
  expect_device_output("png", "image/png")
})
test_that("svg produces an image", {
  expect_device_output("svg", "image/svg+xml", "cairo")
})
test_that("bmp produces an image", {
  expect_device_output("bmp", "image/bmp", "cairo")
})
test_that("tiff produces an image", {
  expect_device_output("tiff", "image/tiff")
})
test_that("pdf produces an image", {
  expect_device_output("pdf", "application/pdf", NULL)
})

test_that("agg_png produces an image", {
  expect_device_output("agg_png", "image/png", NULL)
})
test_that("agg_jpeg produces an image", {
  expect_device_output("agg_jpeg", "image/jpeg", NULL)
})
test_that("agg_tiff produces an image", {
  expect_device_output("agg_tiff", "image/tiff", NULL)
})
test_that("svglite produces an image", {
  expect_device_output("svglite", "image/svg+xml", NULL)
})


context("plumb() device serializer")

test_device <- local({
    r <- pr(test_path("files/device.R"))

  function(name, content_type, capability_type = name, test_little = TRUE) {
    if (!capabilities(capability_type)) {
      testthat::skip("Graphics type not supported: ", name)
    }

    resp <- r$serve(make_req("GET", paste0("/", name)), PlumberResponse$new())
    expect_equal(resp$status, 200)
    expect_equal(resp$headers$`Content-Type`, content_type)
    fullsize <- length(resp$body)
    expect_gt(fullsize, 1000) # This changes based on R ver/OS, may not be useful.

    if (!isTRUE(test_little)) {
      # do not test the smaller device route
      return()
    }
    resp <- r$serve(make_req("GET", paste0("/little", name)), PlumberResponse$new())
    expect_equal(resp$status, 200)
    expect_equal(resp$headers$`Content-Type`, content_type)
    expect_gt(length(resp$body), 100) # This changes based on R ver/OS, may not be useful.
    expect_lt(length(resp$body), fullsize) # Should be smaller than the full one
  }
})

test_that("png are properly rendered", {
  test_device("png", "image/png")
})
test_that("jpeg are properly rendered", {
  test_device("jpeg", "image/jpeg")
})
test_that("svg are properly rendered", {
  test_device("svg", "image/svg+xml", capability_type = "cairo", test_little = FALSE)
})
