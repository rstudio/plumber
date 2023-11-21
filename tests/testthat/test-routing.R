context("Routing")

test_that("Routing to errors and 404s works", {
  r <- pr(test_path("files/router.R"))
  errors <- 0
  notFounds <- 0

  errRes <- list(a=1)
  notFoundRes <- list(b=2)

  r$setErrorHandler(function(req, res, err){ errors <<- errors + 1; errRes })
  r$set404Handler(function(req, res){ notFounds <<- notFounds + 1; notFoundRes })

  res <- PlumberResponse$new(serializer = serializer_identity())

  expect_equal(r$route(make_req("GET", "/"), res), "first")
  expect_equal(r$route(make_req("GET", "/abc"), res), "abc get")
  expect_equal(r$route(make_req("GET", "/dog"), res), "dog get")
  expect_equal(r$route(make_req("POST", "/dog"), res), "dog use")
  expect_equal(r$route(make_req("GET", "/path1"), res), "dual path")
  expect_equal(r$route(make_req("GET", "/path2"), res), "dual path")

  ## Mounts fall back to parent router when route is not found
  # Mount at `/say` with route `/hello`
  expect_equal(r$route(make_req("GET", "/say/hello"), res), "say hello")
  # Mount at `/say/hello` with route `/world`
  expect_equal(r$route(make_req("GET", "/say/hello/world"), res), "say hello world")

  expect_equal(errors, 0)
  expect_equal(notFounds, 0)

  res <- PlumberResponse$new(serializer = serializer_identity())
  nf <- r$serve(make_req("GET", "/something-crazy"), res)
  expect_equal(res$serializer, serializer_identity())
  expect_equal(nf$body, notFoundRes)
  expect_equal(notFounds, 1)

  res <- PlumberResponse$new(serializer = serializer_identity())
  er <- r$serve(make_req("GET", "/error"), res)
  expect_equal(res$serializer, serializer_identity())
  expect_equal(er$body, errRes)
  expect_equal(errors, 1)
})
