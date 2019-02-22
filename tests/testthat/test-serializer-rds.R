context("rds serializer")

test_that("rds serializes properly", {
  v <- iris[0,]
  attr(v, "origin") <- iris
  val <- serializer_rds()(v, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/octet-stream")
  expect_equal(val$body, serialize(v, NULL, ascii = FALSE))
  expect_equal(unserialize(val$body), v)
})


test_that("rds3 serializes properly", {

  testthat::skip_if(package_version(R.version) < "3.5")

  v <- iris[0,]
  attr(v, "origin") <- iris
  # version 3 added in R 3.5
  val <- serializer_rds3()(v, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/octet-stream")
  expect_equal(val$body, serialize(v, NULL, ascii = FALSE, version = "3"))
  expect_equal(unserialize(val$body), v)
})
