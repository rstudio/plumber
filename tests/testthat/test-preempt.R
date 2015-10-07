test_that("preempts work", {
  r <- plumber$new("files/preempt.R")
  expect_equal(length(r$endpoints), 3)

  e <- r$endpoints[["testFun"]][[1]]
  expect_equal(e$preempt, "testFun")

  e <- r$endpoints[["testFun2"]][[1]]
  expect_equal(e$preempt, "testFun2")

  e <- r$endpoints[["testFun3"]][[1]]
  expect_equal(e$preempt, "testFun3")
})

test_that("Redundant preempts fail", {
  expect_error(plumber$new("files/preempt-redundant.R"), regexp="Multiple @preempts")
})

test_that("Empty preempts fail", {
  expect_error(plumber$new("files/preempt-empty.R"), regexp="No @preempt specified")
})

test_that("Non-existant preempts fail", {
  expect_error(plumber$new("files/preempt-nonexistent.R"), regexp="The given @preempt")
})
