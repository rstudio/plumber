make_server_yml_app <- function(plumber_lines, filename = "plumber.R") {
  app_dir <- withr::local_tempdir(.local_envir = parent.frame())
  writeLines("engine: plumber", file.path(app_dir, "_server.yml"))
  writeLines(plumber_lines, file.path(app_dir, filename))
  app_dir
}

test_that("launch_server starts the API beside _server.yml", {
  app_dir <- make_server_yml_app(c(
    "#* @get /ping",
    "function() 'pong'"
  ))

  local_mocked_bindings(
    pr_run = function(pr, host = "127.0.0.1", port = NULL, ...) {
      list(pr = pr, host = host, port = port, dots = list(...))
    }
  )

  result <- launch_server(
    file.path(app_dir, "_server.yml"),
    host = "0.0.0.0",
    port = 8080,
    quiet = TRUE
  )

  expect_s3_class(result$pr, "Plumber")
  expect_true(router_has_route(result$pr, "/ping", "GET"))
  expect_true(router_has_route(result$pr, "/", "GET"))
  expect_identical(result$host, "0.0.0.0")
  expect_identical(result$port, 8080)
  expect_true(result$dots$quiet)

  root_endpoint <- Filter(
    function(endpoint) identical(endpoint$path, "/"),
    result$pr$endpoints[["__no-preempt__"]]
  )[[1]]
  response <- root_endpoint$getFunc()(
    make_req("GET", "/"),
    PlumberResponse$new()
  )
  expect_identical(response$status, 301)
  expect_identical(response$headers$Location, "./__docs__/")
})

test_that("launch_server leaves host and port defaults to pr_run", {
  app_dir <- make_server_yml_app(c(
    "#* @get /ping",
    "function() 'pong'"
  ))

  local_mocked_bindings(
    pr_run = function(pr, host = "default-host", port = "default-port", ...) {
      list(host = host, port = port)
    }
  )

  result <- launch_server(file.path(app_dir, "_server.yml"))

  expect_identical(result$host, "default-host")
  expect_identical(result$port, "default-port")
})

test_that("launch_server supports entrypoint.R applications", {
  app_dir <- make_server_yml_app(c(
    "plumber::pr_get(",
    "  plumber::pr(), '/ping', function() 'pong'",
    ")"
  ), filename = "entrypoint.R")

  local_mocked_bindings(pr_run = function(pr, ...) pr)
  router <- launch_server(file.path(app_dir, "_server.yml"))

  expect_true(router_has_route(router, "/ping", "GET"))
})

test_that("launch_server does not replace an application root route", {
  app_dir <- make_server_yml_app(c(
    "#* @get /",
    "function() 'home'"
  ))

  local_mocked_bindings(pr_run = function(pr, ...) pr)
  router <- launch_server(file.path(app_dir, "_server.yml"))
  root_endpoints <- Filter(
    function(endpoint) identical(endpoint$path, "/"),
    router$endpoints[["__no-preempt__"]]
  )

  expect_length(root_endpoints, 1L)
})

test_that("server docs redirect respects apiPath", {
  app_dir <- make_server_yml_app(c(
    "#* @get /ping",
    "function() 'pong'"
  ))

  withr::local_options(plumber.apiPath = "/service")
  local_mocked_bindings(pr_run = function(pr, ...) pr)
  router <- launch_server(file.path(app_dir, "_server.yml"))

  expect_true(router_has_route(router, "/service/", "GET"))
  expect_false(router_has_route(router, "/", "GET"))
})

test_that("launch_server requires one settings path", {
  expect_error(launch_server(NULL), "must be the path")
  expect_error(launch_server(c("a", "b")), "must be the path")
  expect_error(launch_server(NA_character_), "must be the path")
})
