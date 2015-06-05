test_that("Filters work", {
  r <- RapierRouter$new("files/filters.R")
  expect_equal(length(r$filters), 2)

  expect_equal(r$filters[[1]]$name, "something")
  expect_equal(r$filters[[2]]$name, "nospace")
})

test_that("Redundant filters fail", {
  expect_error(RapierRouter$new("files/filter-redundant.R"), regexp="Multiple @filters")
})

test_that("Empty filters fail", {
  expect_error(RapierRouter$new("files/filter-empty.R"), regexp="No @filter name specified")
})

test_that("Filter and path fails", {
  expect_error(RapierRouter$new("files/filterpath.R"), regexp="both a filter and an API endpoint")
})

make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req
}

test_that("Terminal filters indeed terminate", {
  res <- list()
  r <- RapierRouter$new("files/terminal-filter.R")
  expect_equal(r$route(make_req("GET", "/"), res)$value, 1)
})
