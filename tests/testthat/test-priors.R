test_that("Priors work", {
  r <- RapierSource$new("files/prior.R")
  expect_equal(length(r$endpoints), 3)

  e <- r$endpoints[[1]]
  expect_equal(e$prior, "test")

  e <- r$endpoints[[2]]
  expect_equal(e$prior, "test2")

  e <- r$endpoints[[3]]
  expect_equal(e$prior, "test3")
})

test_that("Redundant priors fail", {
  expect_error(RapierSource$new("files/prior-redundant.R"), regexp="Multiple @priors")
})

test_that("Empty priors fail", {
  expect_error(RapierSource$new("files/prior-empty.R"), regexp="No @prior specified")
})
