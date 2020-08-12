context("Endpoints")

test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(){ a }")

  r <- PlumberEndpoint$new('verb', 'path', foo, env, 1:2)
  expect_equal(r$exec(), 5)
})

test_that("Missing lines are ok", {
  expect_silent({
    PlumberEndpoint$new('verb', 'path', { 1 }, new.env(parent = globalenv()))
  })
})

test_that("Endpoints are exec'able with named arguments.", {
  foo <- parse(text="foo <- function(x){ x + 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(x=3), 4)
})

test_that("Unnamed arguments error", {
  foo <- parse(text="foo <- function(){ 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_error(r$exec(3))

  foo <- parse(text="foo <- function(x, ...){ x + 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_error(r$exec(x=1, 3))
})

test_that("Ellipses allow any named args through", {
  foo <- parse(text="function(...){ sum(unlist(list(...))) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(a=1, b=2, c=3), 6)

  lapply(
    c(
      "", # with no req or res formals
      "req, res, "
    ),
    function(txt) {
      foo <- parse(text=paste0("function(", txt, "...){ list(...) }"))
      r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
      expect_equal(r$exec(a="aa", b="ba"), list(a="aa", b="ba"))
      expect_equal(r$exec(a="aa1", a="aa2", b = "ba"), list(a="aa1", a="aa2", b = "ba"))

      foo <- parse(text=paste0("function(", txt, "a, ...){ list(a, ...) }"))
      r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
      expect_error(r$exec(a="aa1", a="aa2", b = "ba"), "duplicated matching formal arguments")
    }
  )
})

test_that("If only req and res are defined, duplicated arguments do not throw an error", {
  foo <- parse(text="function(req){ req }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = 1, req = 2, res = 3, res = 4), 1)

  foo <- parse(text="function(res){ res }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = 1, req = 2, res = 3, res = 4), 3)

  foo <- parse(text="function(req, res){ list(req, res) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_equal(r$exec(req = 1, req = 2, res = 3, res = 4), list(1,3))

  foo <- parse(text="function(req, res, ...){ -1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, new.env(parent = globalenv()))
  expect_error(r$exec(req = 1, req = 2, res = 3, res = 4), "duplicated matching formal arguments")
})

test_that("Programmatic endpoints work", {
  r <- plumber$new()

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
  r <- plumber$new()

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
