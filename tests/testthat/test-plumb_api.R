context("plumb() package APIs")


expect_apis <- function(apis) {
  expect_s3_class(apis, "plumber_available_apis")
  expect_s3_class(apis, "data.frame")
  expect_true(all(c("package", "name") %in% names(apis)))
}
test_that("available_apis() works with no package", {
  skip_on_cran()

  apis <- available_apis()
  expect_apis(apis)
})
test_that("available_apis() works with a package", {
  apis <- available_apis("plumber")
  expect_apis(apis)
})
test_that("available_apis() print method works", {
  apis_output <- capture.output({
    available_apis("plumber")
  })

  expected_apis_output <- c(
    "Available Plumber APIs:",
    "* plumber",
    paste0("  - ", dir(system.file("plumber", package = "plumber")))
  )

  expect_equal(
    apis_output,
    expected_apis_output
  )
})

test_that("missing args are handled", {
  expect_equal(plumb_api("plumber", NULL), available_apis("plumber"))

  skip_on_cran()
  all_apis <- available_apis()
  expect_equal(plumb_api(NULL, "01-append"), all_apis)
  expect_equal(plumb_api(NULL, NULL), all_apis)
})

test_that("errors are thrown", {


  expect_error(plumb_api(c("plumber", "plumber"), "01-append"))
  expect_error(plumb_api("plumber", c("01-append", "01-append")))

  expect_error(plumb_api(TRUE, "01-append"))
  expect_error(plumb_api("plumber", TRUE))

  expect_error(plumb_api("plumber", "not an api"))

  expect_error(available_apis("not a package"), "No package found with name")
  expect_error(available_apis("crayon"), "No Plumber APIs found for package")
})


context("plumb() plumber APIs")
test_that("all example plumber apis plumb", {
  # plumb each api and validate they return a plumber object
  for_each_plumber_api(identity)
})
