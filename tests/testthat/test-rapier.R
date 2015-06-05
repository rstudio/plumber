test_that("Endpoints are properly identified", {
  r <- RapierRouter$new("files/endpoints.R")
  expect_equal(length(r$endpoints), 4)
  expect_equal(r$endpoints[[1]]$exec(), 5)
  expect_equal(r$endpoints[[2]]$exec(), 10)
  expect_equal(r$endpoints[[3]]$exec(), 12)
  expect_equal(r$endpoints[[4]]$exec(), 14)
})

test_that("The file is sourced in the envir", {
  r <- RapierRouter$new("files/in-env.R")
  expect_equal(length(r$endpoints), 2)
  expect_equal(r$endpoints[[1]]$exec(), 15)
})

test_that("Verbs translate correctly", {
  r <- RapierRouter$new("files/verbs.R")
  expect_equal(length(r$endpoints), 6)
  expect_equal(r$endpoints[[1]]$verbs, c("get", "put", "post", "delete"))
  expect_equal(r$endpoints[[2]]$verbs, "get")
  expect_equal(r$endpoints[[3]]$verbs, "put")
  expect_equal(r$endpoints[[4]]$verbs, "post")
  expect_equal(r$endpoints[[5]]$verbs, "delete")
  expect_equal(r$endpoints[[6]]$verbs, c("post", "get"))
})

test_that("Invalid file fails gracefully", {
  expect_error(RapierRouter$new("asdfsadf"), regexp="File does not exist.*asdfsadf")
})

test_that("Empty endpoints error", {
  expect_error(RapierRouter$new("files/endpoints-empty.R"), regexp="No path specified")
})
