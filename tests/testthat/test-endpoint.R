test_that("Endpoints execute in their environment", {
  env <- new.env()
  assign("a", 5, envir=env)

  foo <- parse(text="foo <- function(){ a }")

  r <- PlumberEndpoint$new('verb', 'path', foo, env, "a", 1:2)
  expect_equal(r$exec(), 5)
})

test_that("Missing lines are ok", {
  PlumberEndpoint$new('verb', 'path', { 1 }, environment())
})

test_that("Endpoints are exec'able with named arguments.", {
  foo <- parse(text="foo <- function(x){ x + 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(x=3), 4)
})

test_that("Unnamed arguments error", {
  foo <- parse(text="foo <- function(){ 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, environment())
  expect_error(r$exec(3))

  foo <- parse(text="foo <- function(x, ...){ x + 1 }")
  r <- PlumberEndpoint$new('verb', 'path', foo, environment())
  expect_error(r$exec(x=1, 3))
})

test_that("Ellipses allow any named args through", {
  foo <- parse(text="function(...){ sum(unlist(list(...))) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(a=1, b=2, c=3), 6)

  foo <- parse(text="function(...){ list(...) }")
  r <- PlumberEndpoint$new('verb', 'path', foo, environment())
  expect_equal(r$exec(a="aa", b="ba"), list(a="aa", b="ba"))
})

test_that("Programmatic endpoints work", {
  r <- plumber$new()
  processor <- PlumberProcessor$new("proc1", function(req, res, data){
    data$pre <- TRUE
  }, function(val, req, res, data){
    res$setHeader("post", TRUE)
    res$setHeader("pre", data$pre)
  })

  serializer <- "ser"
  expr <- expression(function(req, res){res$setHeader("expr", TRUE)})

  r$addEndpoint("GET", "/", expr, serializer, list(processor), "queryString")
  expect_equal(length(r$endpoints), 1)

  end <- r$endpoints[[1]][[1]]
  expect_equal(end$verbs, "GET")
  expect_equal(end$path, "/")
  expect_equal(end$preempt, "queryString")
  expect_equal(end$serializer, serializer)

  res <- PlumberResponse$new()
  req <- list()
  end$exec(req=req, res=res)

  h <- res$headers
  expect_true(h$expr)
  expect_true(h$pre)
  expect_true(h$post)
})

test_that("Programmatic endpoints with functions work", {
  r <- plumber$new()

  expr <- function(req, res){res$setHeader("expr", TRUE)}

  r$addEndpoint("GET", "/", expr)
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
