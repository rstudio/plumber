test_that("Names work", {
  r <- RapierSource$new("files/name.R")
  expect_equal(length(r$endpoints), 3)

  e <- r$endpoints[[1]]
  expect_equal(e$name, "a")

  e <- r$endpoints[[2]]
  expect_equal(e$name, "b")

  e <- r$endpoints[[3]]
  expect_true(is.na(e$name))
})

test_that("Redundant names fail", {
  expect_error(RapierSource$new("files/name-redundant.R"), regexp="Multiple @names")
})

test_that("Empty names fail", {
  expect_error(RapierSource$new("files/name-empty.R"), regexp="No @name specified")
})
