make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Filters work", {
  r <- plumber$new("files/filters.R")
  expect_equal(length(r$filters), 2+2) #2 for post and query string filters

  expect_equal(r$filters[[3]]$name, "something")
  expect_equal(r$filters[[4]]$name, "nospace")
})

test_that("Filters can update req$args", {
  r <- plumber$new("files/filters.R")

  req <- make_req("GET", "/")
  res <- PlumberResponse$new()
  expect_equal(r$serve(req, res)$body, jsonlite::toJSON(23))
})

test_that("Redundant filters fail", {
  expect_error(plumber$new("files/filter-redundant.R"), regexp="Multiple @filters")
})

test_that("Empty filters fail", {
  expect_error(plumber$new("files/filter-empty.R"), regexp="No @filter name specified")
})

test_that("Filter and path fails", {
  expect_error(plumber$new("files/filterpath.R"), regexp="both a filter and an API endpoint")
})

test_that("Terminal filters indeed terminate", {
  res <- PlumberResponse$new()
  r <- plumber$new("files/terminal-filter.R")
  expect_equal(r$route(make_req("GET", "/"), res), 1)
})

test_that("complete addFilter works", {
  r <- plumber$new()

  processor <- PlumberProcessor$new("proc1", function(req, res, data){
    data$pre <- TRUE
  }, function(val, req, res, data){
    res$setHeader("post", TRUE)
    res$setHeader("pre", data$pre)
  })

  serializer <- "ser"

  name <- "fullFilter"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  baseFilters <- length(r$filters)
  r$addFilter(name, expr, serializer, list(processor))
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
  expect_true(h$pre)
  expect_true(h$post)
})

# No processors or serializer
test_that("sparse addFilter works", {
  r <- plumber$new()

  name <- "sparseFilter"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  baseFilters <- length(r$filters)
  r$addFilter(name, expr)
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
