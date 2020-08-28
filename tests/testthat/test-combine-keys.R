context("combine multipart values")

test_that("multi part keys with same name are combined", {
  # no lists
  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = 2),
    B = list(name = "B", parsed = 3),
    A = list(name = "A", parsed = 4),
    B = list(name = "B", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,4), B = list(3,5)))

  # unnamed lists
  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = list(11, 12)),
    B = list(name = "B", parsed = 3),
    A = list(name = "A", parsed = 4),
    B = list(name = "B", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,list(11,12),4), B = list(3,5)))

  # partial named lists
  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = list(X = 11, 12)),
    B = list(name = "B", parsed = 3),
    A = list(name = "A", parsed = list(Y = 4)),
    B = list(name = "B", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,list(X = 11, 12), list(Y = 4)), B = list(3,5)))

  # named lists
  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = list(X = 11, Y = 12)),
    B = list(name = "B", parsed = 3),
    A = list(name = "A", parsed = list(Z = 4)),
    B = list(name = "B", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,list(X = 11, Y = 12), list(Z = 4)), B = list(3,5)))
})


test_that("multi part keys with all same name", {
  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = 2),
    A = list(name = "A", parsed = 3),
    A = list(name = "A", parsed = 4),
    A = list(name = "A", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,2,3,4,5)))

  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = list(2)),
    A = list(name = "A", parsed = 3),
    A = list(name = "A", parsed = 4),
    A = list(name = "A", parsed = 5)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,list(2),3,4,5)))

  a <- list(
    A = list(name = "A", parsed = 1),
    A = list(name = "A", parsed = list(2)),
    A = list(name = "A", parsed = 3),
    A = list(name = "A", parsed = list(4, 5))
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(1,list(2),3,list(4,5))))
})


test_that("raw values are not combined", {
  x <- charToRaw("testval")
  y <- charToRaw("other testval")

  a <- list(
    A = list(name = "A", parsed = x),
    B = list(name = "B", parsed = 2),
    A = list(name = "A", parsed = y),
    A = list(name = "A", parsed = 4)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x, y, 4), B = 2))

  a <- list(
    A = list(name = "A", parsed = x, filename = "x"),
    B = list(name = "B", parsed = 2),
    A = list(name = "A", parsed = y),
    A = list(name = "A", parsed = 4)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x = x, y, 4), B = 2))

  a <- list(
    A = list(name = "A", parsed = x, filename = "x"),
    B = list(name = "B", parsed = 2, filename = "two"),
    A = list(name = "A", parsed = y),
    A = list(name = "A", parsed = 4)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x = x, y, 4), B = list(two = 2)))

  a <- list(
    A = list(name = "A", parsed = x),
    B = list(name = "B", parsed = 2, filename = "two"),
    A = list(name = "A", parsed = y, filename = "y"),
    A = list(name = "A", parsed = 4)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x, y = y, 4), B = list(two = 2)))

  a <- list(
    A = list(name = "A", parsed = x, filename = "x"),
    B = list(name = "B", parsed = 2, filename = "two"),
    A = list(name = "A", parsed = y, filename = "y"),
    A = list(name = "A", parsed = 4)
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x = x, y = y, 4), B = list(two = 2)))

  a <- list(
    A = list(name = "A", parsed = x, filename = "x"),
    B = list(name = "B", parsed = 2, filename = "two"),
    A = list(name = "A", parsed = y, filename = "y"),
    A = list(name = "A", parsed = 4, filename = "four")
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x = x, y = y, four = 4), B = list(two = 2)))

  a <- list(
    A = list(name = "A", parsed = list(x), filename = "x"),
    B = list(name = "B", parsed = 2, filename = "two"),
    A = list(name = "A", parsed = y, filename = "y"),
    A = list(name = "A", parsed = 4, filename = "four")
  )
  expect_equal(combine_keys(a, "multi"), list(A = list(x = list(x), y = y, four = 4), B = list(two = 2)))
})
