context("Tidy Plumber API")

test_that("pr creates new router", {
  p <- pr()
  expect_equal(class(p), c("plumber", "hookable", "R6"))
})

test_that("pr_handle functions add routes", {
  p <- pr() %>%
    pr_handle(c("GET", "POST"),
              "/foo",
              function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("GET", "POST"))
  expect_equal(ep$path, "/foo")

  p <- pr() %>%
    pr_get("/foo", function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("GET"))
  expect_equal(ep$path, "/foo")

  p <- pr() %>%
    pr_post("/foo", function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("POST"))
  expect_equal(ep$path, "/foo")

  p <- pr() %>%
    pr_put("/foo", function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("PUT"))
  expect_equal(ep$path, "/foo")

  p <- pr() %>%
    pr_delete("/foo", function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("DELETE"))
  expect_equal(ep$path, "/foo")

  p <- pr() %>%
    pr_head("/foo", function() "bar")
  ep <- p$endpoints[[1]][[1]]
  expect_equal(ep$verbs, c("HEAD"))
  expect_equal(ep$path, "/foo")
})

test_that("pr_mount mounts router", {
  p1 <- pr() %>%
    pr_get("/hello", function() "Hello")

  p2 <- pr() %>%
    pr_mount("/hi", pr1)

  expect_equal(length(p2$mounts), 1)
})

test_that("pr_register_hooks registers hooks", {
  p <- pr() %>%
    pr_register_hook("preroute", function() print("Pre-route hook")) %>%
    pr_get("/hello", function() "Hello")

  req <- make_req("GET", "/hello")

  expect_output(p$call(req), "Pre-route hook")

  hooks <- list(
    preroute = function() print("Pre-route hook"),
    postroute = function() print("Post-route hook"),
    preserialize = function() print("Pre-serialize hook"),
    postserialize = function() print("Post-serialize hook")
  )

  p <- pr() %>%
    pr_register_hooks(hooks) %>%
    pr_get("/hello", function() "Hello")

  expect_output(p$call(req), "Pre-route hook")
  expect_output(p$call(req), "Pre-serialize hook")
  expect_output(p$call(req), "Post-route hook")
  expect_output(p$call(req), "Post-serialize hook")
})

test_that("pr_cookie adds cookie", {
  p <- pr() %>%
    pr_cookie(
      randomCookieKey(),
      name = "counter"
    ) %>%
    pr_get("/sessionCounter", function(req) {
      count <- 0
      if (!is.null(req$session$counter)){
        count <- as.numeric(req$session$counter)
      }
      req$session$counter <- count + 1
      return(paste0("This is visit #", count))
    })

  req <- make_req("GET", "/sessionCounter")
  expect_match(p$call(req)$headers$`Set-Cookie`, "^counter=")
})

test_that("pr default functions perform as expected", {
  serialized <- function(...) {
    serializer_content_type("text/plain", function(val) {
      paste0("Serialized value: '", val, "'")
    })
  }

  p <- pr() %>%
    pr_serializer(serialized) %>%
    pr_get("/hello", function() "Hello")

  req <- make_req("GET", "/hello")

  res <- p$call(req)

  expect_equal(res$body, "Serialized value: 'Hello'")
})

test_that("pr_filter adds filters", {
  p <- pr()
  initial_filters <- length(p$filters)
  p <- p %>%
    pr_filter("foo", function() {
      print("Filter foo")
      forward()
    }) %>%
    pr_get("/hello", function() "Hello")

  expect_gt(length(p$filters), initial_filters)
})
