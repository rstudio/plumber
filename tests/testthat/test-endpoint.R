context("Endpoints")

test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(){ a }")

  r <- PlumberEndpoint$new('verb', 'path', foo, env, 1:2)
  expect_equal(r$exec(req = list(), res = 2), 5)
})

test_that("Missing lines are ok", {
  expect_silent({
    PlumberEndpoint$new('verb', 'path', { 1 }, new.env(parent = globalenv()))
  })
})

test_that("Endpoints are exec'able with named arguments.", {
  foo <- parse(text="foo <- function(x){ x + 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = list(args = list(x = 3)), res = 20), 4)
})

test_that("Unnamed arguments do not throw an error", {
  foo <- parse(text="foo <- function(){ -1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = list(args = list(3)), res = 100), -1)

  foo <- parse(text="foo <- function(req, res, x, ...){ x + sum(1, ...) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = list(args = list(x = 3, 1)), res = 100), 5)
})

test_that("Ellipses allow any named args through", {
  foo <- parse(text="function(req, res, ...){ sum(unlist(list(...))) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = list(args = list(a=1, b=2, c=3)), res = 20), 6)

  for ( txt in c(
      "", # with no req or res formals
      "req, res, "
  )) {
    foo <- parse(text=paste0("function(", txt, "...){ ret <- list(...); ret[!names(ret) %in% c('req', 'res')] }"))
    r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
    expect_equal(r$exec(req = list(args = list(a="aa", b="ba")), res = 2), list(a="aa", b="ba"))
    expect_equal(r$exec(req = list(args = list(a="aa1", a="aa2", b = "ba")), res = 2), list(a="aa1", a="aa2", b = "ba"))

    foo <- parse(text=paste0("function(", txt, "a, ...){ ret <- list(a = a, ...); ret[!names(ret) %in% c('req', 'res')] }"))
    r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
    expect_equal(r$exec(req = list(args = list(a="aa1", a="aa2", b = "ba")), res = 2), list(a = "aa1", b = "ba"))
  }
})

test_that("If only req and res are defined, duplicated arguments do not throw an error", {
  full_req <- list(args = list(req = 1, req = 2, res = 3, res = 4))
  full_res <- list(args = list(res = 1, res = 2, res = 3, res = 4))
  foo <- parse(text="function(req){ req }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = full_req, res = full_res), full_req)

  foo <- parse(text="function(res){ res }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = full_req, res = full_res), full_res)

  foo <- parse(text="function(req, res){ list(req, res) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = full_req, res = full_res), list(full_req, full_res))

  foo <- parse(text="function(req, res, ...){ list(req, res, ...) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = full_req, res = full_res), list(full_req, full_res))
})

test_that("Programmatic endpoints work", {
  r <- Plumber$new()

  serializer <- "ser"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  r$handle("GET", "/", expr, "queryString", serializer)
  expect_equal(length(r$endpoints), 1)

  end <- r$endpoints[[1]][[1]]
  expect_equal(end$verbs, "GET")
  expect_equal(end$path, "/")
  expect_equal(names(r$endpoints)[1], "queryString")
  expect_equal(end$serializer, serializer)

  res <- PlumberResponse$new()
  req <- list()
  end$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
})

test_that("Programmatic endpoints with functions work", {
  r <- Plumber$new()

  expr <- function(req, res){res$setHeader("expr", TRUE)}

  r$handle("GET", "/", expr)
  expect_equal(length(r$endpoints), 1)

  end <- r$endpoints[[1]][[1]]
  expect_equal(end$verbs, "GET")
  expect_equal(end$path, "/")

  res <- PlumberResponse$new()
  req <- list()
  end$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
})
