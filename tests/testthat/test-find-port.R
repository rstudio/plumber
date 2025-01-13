context("find port")

test_that("ports can be randomly found", {
  foundPorts <- NULL

  for (i in 1:50){
    p <- getRandomPort()
    expect_gte(p, 3000)
    expect_lte(p, 10000)

    foundPorts <- c(foundPorts, p)
  }

  # It's possible we got a collision or two, but shouldn't have many.
  expect_gt(length(unique(foundPorts)), 45)
})

test_that("global port used if available", {
  .globals$port <- 1234
  expect_equal(findPort(), 1234)
  rm("port", envir = .globals)
})

test_that("integer type is returned", {
  expect_type(findPort(), "integer")
  expect_equal(findPort("8000"), 8000L)
  expect_equal(findPort(8000.00000), 8000L)
})

test_that("throws if provided non-integerish port", {
  expect_error(findPort("blue"))
  expect_error(findPort(8000.0001))
  expect_error(findPort(8000:8002))
})

test_that("throws for invalid ports", {
  expect_error(findPort(800)) # in 0-1024
  expect_error(findPort(123456)) # out of range
  expect_error(findPort(0)) # unsafe
  expect_error(findPort(6666)) # unsafe
})

test_that("finds a good port and persists it", {
  testthat::skip_on_cran()

  p <- findPort()

  # Persisted
  expect_equal(.globals$port, p)

  # Check that we can actually start a server
  srv <- httpuv::startServer("127.0.0.1", p, list())

  # Cleanup
  rm("port", envir = .globals)
  httpuv::stopServer(srv)
})

test_that("we don't pin to globals$port if it's occupied", {
  testthat::skip_on_cran()

  srv <- httpuv::startServer("127.0.0.1", 1234, list())
  .globals$port <- 1234

  p <- findPort()

  # It should shuffle to find another port.
  expect_true(p != 1234)

  rm("port", envir = .globals)
  httpuv::stopServer(srv)
})
