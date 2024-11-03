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
