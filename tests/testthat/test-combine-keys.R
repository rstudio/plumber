context("combine keys")

test_that("query keys with same name are combined", {
  a <- c(list(A = 1), list(A = 2), B = 3, A = 4, B = 5)
  expect_equal(combine_keys(a, "query"), list(A = c(1,2,4), B = c(3,5)))
})

test_that("multi part keys with same name are combined", {
  a <- c(list(A = 1), list(A = 2), B = 3, A = 4, B = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,4), B = list(3,5)))
})


test_that("multi part keys with no name are left alone", {
  a <- c(list(A = 1), 2, list(A = 3), list(B = 4), 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,3), B = 4, 2, 5))
})


test_that("multi part keys with no names are untouched", {
  a <- list(1,2,3,4,5)
  expect_equal(combine_keys(a, "multi"), a)
})

test_that("multi part keys with all same name", {
  a <- list(A = 1,A = 2,A = 3,A = 4,A = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,5)))
})
