context("Routing")

test_that("Routing to errors and 404s works", {
  r <- pr(test_path("files/router.R"))
  errors <- 0
  notFounds <- 0

  errRes <- list(a=1)
  notFoundRes <- list(b=2)

  r$setErrorHandler(function(req, res, err){ errors <<- errors + 1; errRes })
  r$set404Handler(function(req, res){ notFounds <<- notFounds + 1; notFoundRes })

  res <- PlumberResponse$new()

  expect_equal(r$route(make_req("GET", "/"), res), "first")
  expect_equal(r$route(make_req("GET", "/abc"), res), "abc get")
  expect_equal(r$route(make_req("GET", "/dog"), res), "dog get")
  expect_equal(r$route(make_req("POST", "/dog"), res), "dog use")
  expect_equal(r$route(make_req("GET", "/path1"), res), "dual path")
  expect_equal(r$route(make_req("GET", "/path2"), res), "dual path")

  expect_equal(errors, 0)
  expect_equal(notFounds, 0)

  nf <- r$route(make_req("GET", "/something-crazy"), res)
  expect_equal(res$serializer, serializer_json())
  expect_equal(nf, notFoundRes)
  expect_equal(notFounds, 1)

  er <- r$route(make_req("GET", "/error"), res)
  expect_equal(res$serializer, serializer_json())
  expect_equal(er, errRes)
  expect_equal(errors, 1)
})


test_that("mounts with more specific paths are used", {

  root <- pr() %>%
    pr_mount("/aaa",
      pr() %>%
        pr_get("/bbb/hello", function() "/aaa - /bbb/hello") %>%
        pr_get("/bbb/test", function() "/aaa - /bbb/test")
    ) %>%
    pr_mount("/aaa/bbb",
      pr() %>%
        pr_get("/hello", function() "/aaa/bbb - /hello") %>%
        pr_set_404(function(...) { "404" })
    )


  # make sure it can print without error... which calls root$routes
  expect_error(capture.output(print(root)), NA)

  res <- PlumberResponse$new()
  # route with more specific mount is used
  expect_equal(
    root$route(make_req("GET", "/aaa/bbb/hello"), res),
    "/aaa/bbb - /hello"
  )

  # currently "bad" behavior. TODO - make this return "/aaa - /bbb/test"
  expect_equal(
    root$route(make_req("GET", "/aaa/bbb/test"), res),
    "404"
  )


})
