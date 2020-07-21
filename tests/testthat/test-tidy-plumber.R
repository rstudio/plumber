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
    pr_mount("/hi", p1)

  expect_equal(length(p2$mounts), 1)
})

test_that("pr_hooks registers hooks", {
  p <- pr() %>%
    pr_hook("preroute", function() print("Pre-route hook")) %>%
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
    pr_hooks(hooks) %>%
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
  # Serializer
  serialized <- function(...) {
    serializer_content_type("text/plain", function(val) {
      paste0("Serialized value: '", val, "'")
    })
  }

  p <- pr() %>%
    pr_set_serializer(serialized()) %>%
    pr_get("/hello", function() "Hello")

  req <- make_req("GET", "/hello")

  res <- p$call(req)

  expect_equal(res$body, "Serialized value: 'Hello'")

  # 404 Handler
  handler_404 <- function(req, res) {
    res$status <- 404
    res$body <- "Oops"
  }

  p <- pr() %>%
    pr_get("/hello", function() "Hello") %>%
    pr_set_404(handler_404)

  req <- make_req("GET", "/foo")

  res <- p$call(req)

  expect_equal(res$status, 404)
  expect_equal(res$body, jsonlite::toJSON("Oops"))

  # Error handler
  handler_error <- function(req, res, err){
    res$status <- 500
    list(error = "Custom Error Message")
  }

  p <- pr() %>%
    pr_get("/error", function() log("a")) %>%
    pr_set_error(handler_error)

  req <- make_req("GET", "/error")

  res <- p$call(req)

  expect_equal(res$status, 500)
  expect_equal(jsonlite::fromJSON(res$body)[[1]], "Custom Error Message")
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
