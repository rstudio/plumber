test_that("Endpoints are properly identified", {
  r <- plumber$new("files/endpoints.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 5)
  expect_equal(r$endpoints[[1]][[2]]$exec(), 10)
  expect_equal(r$endpoints[[1]][[3]]$exec(), 12)
  expect_equal(r$endpoints[[1]][[4]]$exec(), 14)
})

test_that("Empty file is OK", {
  r <- plumber$new()
  expect_equal(length(r$endpoints), 0)
})

test_that("The file is sourced in the envir", {
  r <- plumber$new("files/in-env.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 2)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 15)
})

test_that("Verbs translate correctly", {
  r <- plumber$new("files/verbs.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 6)
  expect_equal(r$endpoints[[1]][[1]]$verbs, c("GET", "PUT", "POST", "DELETE"))
  expect_equal(r$endpoints[[1]][[2]]$verbs, "GET")
  expect_equal(r$endpoints[[1]][[3]]$verbs, "PUT")
  expect_equal(r$endpoints[[1]][[4]]$verbs, "POST")
  expect_equal(r$endpoints[[1]][[5]]$verbs, "DELETE")
  expect_equal(r$endpoints[[1]][[6]]$verbs, c("POST", "GET"))
})

test_that("Invalid file fails gracefully", {
  expect_error(plumber$new("asdfsadf"), regexp="File does not exist.*asdfsadf")
})

test_that("Empty endpoints error", {
  expect_error(plumber$new("files/endpoints-empty.R"), regexp="No path specified")
})

test_that("The old roxygen-style comments work", {
  r <- plumber$new("files/endpoints-old.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 5)
  expect_equal(r$endpoints[[1]][[2]]$exec(), 10)
  expect_equal(r$endpoints[[1]][[3]]$exec(), 12)
  expect_equal(r$endpoints[[1]][[4]]$exec(), 14)
})

