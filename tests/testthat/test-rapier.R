test_that("Endpoints are properly identified", {
  r <- RapierSource$new("files/endpoints.R")
  expect_equal(length(r$endpoints), 4)
  expect_equal(r$endpoints[[1]]$exec(), 5)
  expect_equal(r$endpoints[[2]]$exec(), 10)
  expect_equal(r$endpoints[[3]]$exec(), 12)
  expect_equal(r$endpoints[[4]]$exec(), 14)
})

test_that("The file is sourced in the envir", {
  r <- RapierSource$new("files/hello.R")
  expect_equal(length(r$endpoints), 2)
  expect_equal(r$endpoints[[1]]$exec(1), 15)
})

test_that("Verbs translate correctly", {
  r <- RapierSource$new("files/verbs.R")
  expect_equal(length(r$endpoints), 6)
  expect_equal(r$endpoints[[1]]$verbs, c("get", "put", "post", "delete"))
  expect_equal(r$endpoints[[2]]$verbs, "get")
  expect_equal(r$endpoints[[3]]$verbs, "put")
  expect_equal(r$endpoints[[4]]$verbs, "post")
  expect_equal(r$endpoints[[5]]$verbs, "delete")
  expect_equal(r$endpoints[[6]]$verbs, c("post", "get"))
})

test_that("Includes and excludes work", {
  r <- RapierSource$new("files/inexcludes.R")
  expect_equal(length(r$endpoints), 3)

  e <- r$endpoints[[1]]
  expect_equal(e$includes, "inc")
  expect_equal(e$excludes, "exc")

  e <- r$endpoints[[2]]
  expect_equal(e$includes, "inc")
  expect_equal(e$excludes, c("exc2", "exc1"))

  e <- r$endpoints[[3]]
  expect_equal(e$includes, NA)
  expect_equal(e$excludes, c("exc3", "exc2", "exc1"))
})

test_that("Redundant includes fail", {
  expect_error(RapierSource$new("files/inexclude-redundant.R"), regexp="Redundant @include")
})

test_that("Invalid file fails gracefully", {
  expect_error(RapierSource$new("asdfsadf"), regexp="File does not exist.*asdfsadf")
})
