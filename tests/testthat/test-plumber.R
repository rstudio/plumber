context("Plumber")

test_that("Endpoints are properly identified", {
  r <- plumber$new("files/endpoints.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 5)
  expect_equal(r$endpoints[[1]][[2]]$exec(), 10)
  expect_equal(r$endpoints[[1]][[3]]$exec(), 12)
  expect_equal(r$endpoints[[1]][[4]]$exec(), 14)
})

test_that("Empty file is OK", {
  r <- plumber$new()
  expect_equal(length(r$endpoints), 0)
})

test_that("The file is sourced in the envir", {
  r <- plumber$new("files/in-env.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 3)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 15)
})

test_that("Verbs translate correctly", {
  r <- plumber$new("files/verbs.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 8)
  expect_equal(r$endpoints[[1]][[1]]$verbs, c("GET", "PUT", "POST", "DELETE", "HEAD", "OPTIONS"))
  expect_equal(r$endpoints[[1]][[2]]$verbs, "GET")
  expect_equal(r$endpoints[[1]][[3]]$verbs, "PUT")
  expect_equal(r$endpoints[[1]][[4]]$verbs, "POST")
  expect_equal(r$endpoints[[1]][[5]]$verbs, "DELETE")
  expect_equal(r$endpoints[[1]][[6]]$verbs, c("POST", "GET"))
  expect_equal(r$endpoints[[1]][[7]]$verbs, "HEAD")
  expect_equal(r$endpoints[[1]][[8]]$verbs, "OPTIONS")
})

test_that("Invalid file fails gracefully", {
  expect_error(plumber$new("asdfsadf"), regexp="File does not exist.*asdfsadf")
})

test_that("plumb accepts a file", {
  r <- plumb("files/endpoints.R")
  expect_length(r$endpoints[[1]], 4)
})

test_that("plumb accepts a directory with a `plumber.R` file", {
  # works without trailing slash
  r <- plumb(dir = 'files')
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)

  # works with trailing slash
  r <- plumb(dir = 'files/')
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)

  # errors when no plumber.R found
  expect_error(plumb(dir = 'files/static'), regexp="File does not exist: files/static/plumber.R")
  # errors when neither dir is empty and file is not given
  expect_error(plumb(dir=""), regexp="You must specify either a file or directory*")
  # reads from working dir if no args
  expect_error(plumb(), regexp="File does not exist: ./plumber.R")
  # errors when both dir and file are given
  expect_error(plumb(file="files/endpoints.R", dir="files"), regexp="You must set either the file or the directory parameter, not both")
})

test_that("plumb() a dir leverages `entrypoint.R`", {
  expect_null(plumber:::.globals$serializers$fake, "This just that your Plumber environment is dirty. Restart your R session.")

  r <- plumb(dir = 'files/entrypoint/')
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 1)

  # A global serializer was added by entrypoint.R before parsing
  expect_true(!is.null(plumber:::.globals$serializers$fake))

  # Clean up after ourselves
  gl <- plumber:::.globals
  gl$serializers["fake"] <- NULL
})

test_that("bad `entrypoint.R`s throw", {
  expect_error(plumb(dir = 'files/entrypoint-bad/'), "runnable Plumber router")
})

test_that("Empty endpoints error", {
  expect_error(plumber$new("files/endpoints-empty.R"), regexp="No path specified")
})

test_that("The old roxygen-style comments work", {
  r <- plumber$new("files/endpoints-old.R")
  expect_equal(length(r$endpoints), 1)
  expect_equal(length(r$endpoints[[1]]), 4)
  expect_equal(r$endpoints[[1]][[1]]$exec(), 5)
  expect_equal(r$endpoints[[1]][[2]]$exec(), 10)
  expect_equal(r$endpoints[[1]][[3]]$exec(), 12)
  expect_equal(r$endpoints[[1]][[4]]$exec(), 14)
})

test_that("routes can be constructed correctly", {
  pr <- plumber$new()
  pr$handle("GET", "/nested/path/here", function(){})
  pr$handle("POST", "/nested/path/here", function(){})

  pr2 <- plumber$new()
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})
  pr$mount("/mysubpath", pr2)

  stat <- PlumberStatic$new(".")
  pr$mount("/static", stat)

  expect_length(pr$routes, 3)
  expect_true("plumberstatic" %in% class(pr$routes[["static"]]))
  expect_true("plumber" %in% class(pr$routes[["mysubpath"]]))

  # 2 endpoints at the same location (different verbs)
  expect_length(pr$routes$nested$path$here, 2)
})

test_that("mounts can be read correctly", {
  pr <- plumber$new()
  pr$handle("GET", "/nested/path/here", function(){})
  pr$handle("POST", "/nested/path/here", function(){})

  pr2 <- plumber$new()
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})
  pr$mount("/mysubpath", pr2)

  stat <- PlumberStatic$new(".")
  pr$mount("/static", stat)

  expect_length(pr$routes, 3)
  expect_true("plumberstatic" %in% class(pr$mounts[["/static/"]]))
  expect_true("plumber" %in% class(pr$mounts[["/mysubpath/"]]))
})

test_that("prints correctly", {
  pr <- plumber$new()
  pr$handle("GET", "/nested/path/here", function(){})
  pr$handle("POST", "/nested/path/here", function(){})

  pr2 <- plumber$new()
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})
  pr$mount("/mysubpath", pr2)

  stat <- PlumberStatic$new(".")
  pr$mount("/static", stat)

  printed <- capture.output(print(pr))

  regexps <- c(
    "Plumber router with 2 endpoints, 4 filters, and 2 sub-routers",
    "Call run\\(\\) on this object",
    "├──\\[queryString\\]",
    "├──\\[postBody\\]",
    "├──\\[cookieParser\\]",
    "├──\\[sharedSecret\\]",
    "├──/nested",
    "│  ├──/path",
    "│  │  └──/here \\(GET, POST\\)",
    "├──/mysubpath",
    "│  │ # Plumber router with 2 endpoints, 4 filters, and 0 sub-routers.",
    "│  ├──\\[queryString\\]",
    "│  ├──\\[postBody\\]",
    "│  ├──\\[cookieParser\\]",
    "│  ├──\\[sharedSecret\\]",
    "│  ├──/something \\(POST\\)",
    "│  └──/ \\(GET\\)",
    "├──/static",
    "│  │ # Plumber static router serving from directory: \\."
  )

  for (i in 1:length(regexps)){
    expect_match(printed[i], regexps[i], info=paste0("on line ", i))
  }

})

test_that("mounts work", {
  pr <- plumber$new()
  sub <- plumber$new()
  sub$handle("GET", "/", function(){ 1 })
  sub$handle("GET", "/nested/path", function(){ 2 })

  pr$mount("/subpath", sub)

  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/nested/path"), res)
  expect_equal(res$status, 404)

  val <- pr$route(make_req("GET", "/subpath/nested/path"), PlumberResponse$new())
  expect_equal(val, 2)

  val <- pr$route(make_req("GET", "/subpath/"), PlumberResponse$new())
  expect_equal(val, 1)
})

test_that("mounting at root path works", {
  pr <- plumber$new()
  sub <- plumber$new()
  sub$handle("GET", "/", function(){ 1 })
  sub$handle("GET", "/nested/path", function(){ 2 })

  pr$mount("/", sub)

  val <- pr$route(make_req("GET", "/nested/path"), PlumberResponse$new())
  expect_equal(val, 2)

  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_equal(val, 1)
})

test_that("conflicting mounts behave consistently", {
  pr <- plumber$new()

  sub <- plumber$new()
  sub$handle("GET", "/", function(){ 1 })
  pr$mount("/subpath", sub)

  val <- pr$route(make_req("GET", "/subpath/"), PlumberResponse$new())
  expect_equal(val, 1)

  pr$handle("GET", "/subpath/", function(){ 2 })

  val <- pr$route(make_req("GET", "/subpath/"), PlumberResponse$new())
  expect_equal(val, 2)
})

test_that("hooks can be registered", {
  pr <- plumber$new()
  events <- NULL
  pr$handle("GET", "/", function(){ events <<- c(events, "exec") })
  pr$registerHook("preroute", function(){ events <<- c(events, "preroute") })
  pr$registerHook("postroute", function(){ events <<- c(events, "postroute") })
  pr$registerHook("preserialize", function(){ events <<- c(events, "preserialize") })
  pr$registerHook("postserialize", function(){ events <<- c(events, "postserialize") })

  pr$serve(make_req("GET", "/"), PlumberResponse$new())
  expect_equal(events, c("preroute", "exec", "postroute", "preserialize", "postserialize"))
})

test_that("preroute hook gets the right data", {
  pr <- plumber$new()
  pr$handle("GET", "/", function(){ })
  rqst <- make_req("GET", "/")

  pr$registerHook("preroute", function(data, req, res){
    expect_true("PlumberResponse" %in% class(res))
    expect_equal(rqst, req)
    expect_true(is.environment(data))
  })
  pr$serve(rqst, PlumberResponse$new())
})

test_that("postroute hook gets the right data", {
  pr <- plumber$new()
  pr$handle("GET", "/abc", function(){ 123 })

  pr$registerHook("postroute", function(data, req, res, value){
    expect_true("PlumberResponse" %in% class(res))
    expect_equal(req$PATH_INFO, "/abc")
    expect_true(is.environment(data))
    expect_equal(value, 123)
  })
  pr$serve(make_req("GET", "/abc"), PlumberResponse$new())
})

test_that("preserialize hook gets the right data", {
  pr <- plumber$new()
  pr$handle("GET", "/abc", function(){ 123 })

  pr$registerHook("preserialize", function(data, req, res, value){
    expect_true("PlumberResponse" %in% class(res))
    expect_equal(req$PATH_INFO, "/abc")
    expect_true(is.environment(data))
    expect_equal(value, 123)
  })
  pr$serve(make_req("GET", "/abc"), PlumberResponse$new())
})

test_that("postserialize hook gets the right data", {
  pr <- plumber$new()
  pr$handle("GET", "/abc", function(){ 123 })

  pr$registerHook("postserialize", function(data, req, res, value){
    expect_true("PlumberResponse" %in% class(res))
    expect_equal(req$PATH_INFO, "/abc")
    expect_true(is.environment(data))
    expect_equal(value, 123)
  })
  pr$serve(make_req("GET", "/abc"), PlumberResponse$new())
})

test_that("invalid hooks err", {
  pr <- plumber$new()
  expect_error(pr$registerHook("flargdarg"))
})

test_that("handle invokes correctly", {
  pr <- plumber$new()
  pr$handle("GET", "/trailslash", function(){ "getter" })
  pr$handle("POST", "/trailslash/", function(){ "poster" })

  expect_equal(pr$route(make_req("GET", "/trailslash"), PlumberResponse$new()), "getter")
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/trailslash/"), res) # With trailing slash
  expect_equal(res$status, 404)
  res <- PlumberResponse$new()
  pr$route(make_req("POST", "/trailslash"), res) # Wrong verb
  expect_equal(res$status, 404)

  expect_equal(pr$route(make_req("POST", "/trailslash/"), PlumberResponse$new()), "poster")
  res <- PlumberResponse$new()
  pr$route(make_req("POST", "/trailslash"), res) # w/o trailing slash
  expect_equal(res$status, 404)
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/trailslash/"), res) # Wrong verb
  expect_equal(res$status, 404)
})

test_that("handle with an endpoint works", {
  pr <- plumber$new()
  ep <- PlumberEndpoint$new("GET", "/", function(){ "manual endpoint" }, pr$environment, serializer_json())
  pr$handle(endpoint=ep)

  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_equal(val, "manual endpoint")
})

test_that("handle with and enpoint and endpoint def fails", {
  pr <- plumber$new()
  ep <- PlumberEndpoint$new("GET", "/", function(){ "manual endpoint" }, pr$environment, serializer_json())
  expect_error(pr$handle("GET", "/", endpoint=ep))
})

test_that("full handle call works", {
  pr <- plumber$new()
  pr$filter("f1", function(req){ req$filtered <- TRUE; forward() })

  pr$handle("GET", "/preempt", function(req){
    expect_null(req$filtered)
    "preempted"
  }, "f1", serializer_unboxed_json())

  pr$handle("GET", "/dontpreempt", function(req){
    expect_true(req$filtered)
    "unpreempted"
  }, serializer=serializer_unboxed_json())

  res <- PlumberResponse$new()
  val <- pr$route(make_req("GET", "/preempt"), res)
  expect_equal(val, "preempted") # no JSON box
  res <- PlumberResponse$new()
  val <- pr$route(make_req("GET", "/dontpreempt"), res)
  expect_equal(val, "unpreempted") # no JSON box
})

test_that("Expressions and functions both work on handle", function(){
  pr <- plumber$new()
  pr$handle("GET", "/function", function(req){ req[["PATH_INFO"]] })
  pr$handle("GET", "/expression", expression(function(req){ req[["PATH_INFO"]] }))

  val <- pr$route(make_req("GET", "/function"), PlumberResponse$new())
  expect_equal(val, "/function")
  val <- pr$route(make_req("GET", "/expression"), PlumberResponse$new())
  expect_equal(val, "/expression")
})

test_that("Expressions and functions both work on filter", function(){
  pr <- plumber$new()
  pr$filter("ff", function(req){ req$filteredF <- TRUE; forward() })
  pr$filter("fe", expression(function(req){ req$filteredE <- TRUE; forward() }))
  pr$handle("GET", "/", function(req){
    req$filteredE && req$filteredF
  })

  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_true(val)

  pr$handle("GET", "/expr", expression(function(req){
    req$filteredE && req$filteredF
  }))

  val <- pr$route(make_req("GET", "/expr"), PlumberResponse$new())
  expect_true(val)
})

test_that("filters and endpoint expressions evaluated in the appropriate (possibly injected) environment", function(){
  # Create an environment that contains a variable named `y`.
  env <- new.env(parent=.GlobalEnv)
  env$y <- 10

  # We provide expressions so that they get closurified in the right environment
  # and will be able to find `y`.
  # This would all fail without an injected environment that contains `y`.
  pr <- plumber$new(envir=env)
  pr$filter("ff", expression(function(req){ req$ys <- y^2; forward() }))
  pr$handle("GET", "/", expression(function(req){ paste(y, req$ys) }))

  # Send a request through and we should see an assign to our env.
  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_equal(val, "10 100")
})

test_that("filters and endpoints executed in the appropriate environment", function(){
  # We've already seen that, if expressions, they're going to be evaluated in the
  # appropriate environment, but we can also confirm that once they've been evaluated,
  # they're then executed in the appropriate environment.

  # This almost certainly doesn't matter unless a function is inspecting the call stack,
  # but for the sake of consistency we not only ensure that any given expressions are
  # evaluated in the appropriate environment, but also that they are then called in the
  # given environment, as well.

  env <- new.env(parent=.GlobalEnv)

  pr <- plumber$new(envir=env)
  pr$filter("ff", expression(function(req){ req$filterEnv <- parent.frame(); forward() }))
  pr$handle("GET", "/", expression(function(req){
    expect_identical(req$filterEnv, parent.frame())
    parent.frame()
  }))

  # Send a request through and we should see an assign to our env.
  val <- pr$route(make_req("GET", "/"), PlumberResponse$new())
  expect_identical(env, val)
})

test_that("Injected plumb environment works", {
  env <- new.env()
  r <- plumb("files/in-env.R", envir=env)
  val <- r$route(make_req("GET", "/envir"), PlumberResponse$new())
  expect_identical(val, env)
})
