test_that("Priors work", {
  r <- RapierRouter$new("files/prior.R")
  expect_equal(length(r$endpoints), 3)

  e <- r$endpoints[[1]]
  expect_equal(e$prior, "testFun")

  e <- r$endpoints[[2]]
  expect_equal(e$prior, "testFun2")

  e <- r$endpoints[[3]]
  expect_equal(e$prior, "testFun3")
})

test_that("Redundant priors fail", {
  expect_error(RapierRouter$new("files/prior-redundant.R"), regexp="Multiple @priors")
})

test_that("Empty priors fail", {
  expect_error(RapierRouter$new("files/prior-empty.R"), regexp="No @prior specified")
})

test_that("Non-existant priors fail", {
  expect_error(RapierRouter$new("files/prior-nonexistent.R"), regexp="The given @prior")
})
