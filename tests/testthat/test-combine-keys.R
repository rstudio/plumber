context("combine keys")

test_that("query keys with same name are combined", {
  a <- list(A = 1, A = 2, B = 3, A = 4, B = 5)
  expect_equal(combine_keys(a, "query"), list(A = c(1,2,4), B = c(3,5)))
})

test_that("multi part keys with same name are combined", {
  # no lists
  a <- list(A = 1, A = 2, B = 3, A = 4, B = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,4), B = list(3,5)))

  # unnamed lists
  a <- list(A = 1, A = list(11,12), B = 3, A = 4, B = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,11,12,4), B = list(3,5)))

  # partial named lists
  a <- list(A = 1, A = list(X = 11,12), B = 3, A = list(Y = 4), B = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,X = 11, 12, Y = 4), B = list(3,5)))

  # named lists
  a <- list(A = 1, A = list(X = 11, Y = 12), B = 3, A = list(Z = 4), B = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,X = 11, Y = 12, Z = 4), B = list(3,5)))
})


test_that("multi part keys with no name are left alone", {
  a <- list(A = 1, 2, A = 3, B = 4, 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,3), B = 4, 2, 5))

  a <- list(A = 1, 2, A = 3, B = 4, 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,3), B = 4, 2, 5))
  a <- list(A = 1, 2, A = 3, B = 4, 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,3), B = 4, 2, 5))
})


test_that("multi part keys with no names are untouched", {
  a <- list(1,2,3,4,5)
  expect_equal(combine_keys(a, "multi"), a)

  a <- list(1,list(2),3,4,5)
  expect_equal(combine_keys(a, "multi"), a)

  a <- list(1,list(2),3,list(4,5))
  expect_equal(combine_keys(a, "multi"), a)

  a <- list(list(1),list(2),list(3),list(4, 5))
  expect_equal(combine_keys(a, "multi"), a)
})

test_that("multi part keys with all same name", {
  a <- list(A = 1, A = 2, A = 3, A = 4, A = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,5)))

  a <- list(A = 1,A = list(2),A = 3,A = 4,A = 5)
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,5)))

  a <- list(A = 1,A = list(2),A = 3,A = list(4,5))
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,5)))

  a <- list(A = 1,A = list(2),A = 3,A = list(4,Y = 5))
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,Y = 5)))

  a <- list(A = 1,A = list(2),A = 3,A = list(X = 4,Y = 5))
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,X = 4,Y = 5)))

  a <- list(A = 1,A = list(B = 2),A = 3,A = list(X = 4,Y = 5))
  expect_equal(combine_keys(a, "multi"), list(A = list(1,B = 2,3,X = 4,Y = 5)))
})


test_that("raw values are not combined", {
  x <- charToRaw("testval")
  y <- charToRaw("other testval")

  a <- list(x,y)
  expect_equal(combine_keys(a, "multi"), list(x, y))

  a <- list(A = x,y)
  expect_equal(combine_keys(a, "multi"), list(A = x, y))

  a <- list(A = x, B = y)
  expect_equal(combine_keys(a, "multi"), list(A = x, B = y))

  a <- list(A = x, A = y)
  expect_equal(combine_keys(a, "multi"), list(A = list(x, y)))

  a <- list(A = list(X = x), A = y)
  a <- list(A = list(X = x), A = list(y))
  expect_equal(combine_keys(a, "multi"), list(A = list(X = x, y)))

  a <- list(A = list(x), A = list(Y = y))
  expect_equal(combine_keys(a, "multi"), list(A = list(x, Y = y)))

  a <- list(A = list(X = x), A = list(Y = y))
  expect_equal(combine_keys(a, "multi"), list(A = list(X = x, Y = y)))


  a <- list(A = list(X = x), A = list(Y = y), A = "foobar")
  expect_equal(combine_keys(a, "multi"), list(A = list(X = x, Y = y, "foobar")))
})


test_that("inner list structures are preserved", {

  a <- list(A = 1, B = 2, A = list(X = 3, Y = 4))
  expect_equal(combine_keys(a, "multi"), list(A = list(1,X = 3, Y = 4), B = 2))
})
