context("filters")

test_that("Filters work", {
  r <- plumber$new(test_path("files/filters.R"))
  expect_equal(length(r$filters), 4+2) #4 for post, query string, cookie, and shared secret filters

  expect_equal(r$filters[[5]]$name, "something")
  expect_equal(r$filters[[6]]$name, "nospace")
})

test_that("Filters can update req$args", {
  r <- plumber$new(test_path("files/filters.R"))
  expect_equal(r$call(make_req("GET", "/"))$body, jsonlite::toJSON(23))
})

test_that("Redundant filters fail", {
  expect_error(plumber$new(test_path("files/filter-redundant.R")), regexp="Multiple @filters")
})

test_that("Empty filters fail", {
  expect_error(plumber$new(test_path("files/filter-empty.R")), regexp="No @filter name specified")
})

test_that("Filter and path fails", {
  expect_error(plumber$new(test_path("files/filterpath.R")), regexp="can only be")
})

test_that("Filter and assets fails", {
  expect_error(plumber$new(test_path("files/filterasset.R")), regexp="can only be")
})

test_that("Terminal filters indeed terminate", {
  r <- plumber$new(test_path("files/terminal-filter.R"))
  expect_equal(r$call(make_req("GET", "/"))$body, jsonlite::toJSON(1))
})

test_that("complete addFilter works", {
  r <- plumber$new()

  serializer <- "ser"

  name <- "fullFilter"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  baseFilters <- length(r$filters)
  r$filter(name, expr, serializer)
  expect_equal(length(r$filters), baseFilters+1)

  fil <- r$filters[[baseFilters+1]]
  expect_equal(fil$name, "fullFilter")
  expect_equal(fil$lines, NA)
  expect_equal(fil$serializer, serializer)

  res <- PlumberResponse$new()
  req <- list()
  fil$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
})

# No processors or serializer
test_that("sparse addFilter works", {
  r <- plumber$new()

  name <- "sparseFilter"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  baseFilters <- length(r$filters)
  r$filter(name, expr)
  expect_equal(length(r$filters), baseFilters+1)

  fil <- r$filters[[baseFilters+1]]
  expect_equal(fil$name, "sparseFilter")
  expect_equal(fil$lines, NA)

  res <- PlumberResponse$new()
  req <- list()
  fil$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
})

test_that("sparse addFilter with a function works", {
  r <- plumber$new()

  name <- "sparseFilter"
  expr <- function(req, res){res$setHeader("expr", TRUE)}

  baseFilters <- length(r$filters)
  r$filter(name, expr)
  expect_equal(length(r$filters), baseFilters+1)

  fil <- r$filters[[baseFilters+1]]
  expect_equal(fil$name, "sparseFilter")
  expect_equal(fil$lines, NA)

  res <- PlumberResponse$new()
  req <- list()
  fil$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
})
