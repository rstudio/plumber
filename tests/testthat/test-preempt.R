context("Preempts")

test_that("preempts work", {
  r <- plumber$new(test_path("files/preempt.R"))
  expect_equal(length(r$endpoints), 3)

  expect_length(r$endpoints[["testFun"]], 1)
  expect_length(r$endpoints[["testFun2"]], 1)
  expect_length(r$endpoints[["testFun3"]], 1)
})

test_that("Redundant preempts fail", {
  expect_error(plumber$new(test_path("files/preempt-redundant.R")), regexp="Multiple @preempts")
})

test_that("Empty preempts fail", {
  expect_error(plumber$new(test_path("files/preempt-empty.R")), regexp="No @preempt specified")
})

test_that("Non-existant preempts fail", {
  expect_error(plumber$new(test_path("files/preempt-nonexistent.R")), regexp="The given @preempt")
})
