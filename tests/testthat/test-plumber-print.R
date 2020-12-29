test_that("prints correctly", {
  testthat::skip_on_cran()
  testthat::skip_on_os("windows") # has issues comparing text values


  pr1 <- pr()
  pr1$handle("GET", "/nested/path/here", function(){})
  pr1$handle("POST", "/nested/path/here", function(){})

  pr2 <- pr()
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})
  pr1$mount("/mysubpath", pr2)

  stat <- PlumberStatic$new(".")
  pr1$mount("/static", stat)

  printed <- capture.output(print(pr1))

  expected_output <- c(
    "# Plumber router with 2 endpoints, 4 filters, and 2 sub-routers.",
    "# Call run() on this object to start the API.",
    "├──[queryString]",
    "├──[body]",
    "├──[cookieParser]",
    "├──[sharedSecret]",
    "├──/mysubpath",
    "│  │ # Plumber router with 2 endpoints, 4 filters, and 0 sub-routers.",
    "│  ├──[queryString]",
    "│  ├──[body]",
    "│  ├──[cookieParser]",
    "│  ├──[sharedSecret]",
    "│  ├──/ (GET)",
    "│  └──/something (POST)",
    "├──/nested",
    "│  ├──/path",
    "│  │  └──/here (GET, POST)",
    "├──/static",
    "│  │ # Plumber static router serving from directory: ."
  )

  expect_equal(printed, expected_output)

  expected_output2 <- c(
    "# Plumber router with 1 endpoint, 4 filters, and 0 sub-routers.",
    "# Call run() on this object to start the API.",
    "├──[queryString]",
    "├──[body]",
    "├──[cookieParser]",
    "├──[sharedSecret]",
    "├──/A",
    "│  ├──/B",
    "│  │  └──/ (GET)"
  )
  printed2 <- capture.output(print(pr_get(pr(), "/A/B/", identity)))
  expect_equal(printed2, expected_output2)
})

test_that("prints correctly", {
  testthat::skip_on_cran()
  testthat::skip_on_os("windows") # has issues comparing text values

  pr1 <- pr()
  sub <- pr()
  sub$handle("GET", "/", force)
  sub$handle("POST", "/something", force)
  sub$handle("GET", "/nested/path", force)
  sub$handle("POST", "/", force)
  sub$handle("POST", "/nested/path", force)

  pr1$mount("/", sub)

  printed <- capture.output(print(pr1))

  expected_output <- c(
    "# Plumber router with 0 endpoints, 4 filters, and 1 sub-router.",
    "# Call run() on this object to start the API.",
    "├──[queryString]",
    "├──[body]",
    "├──[cookieParser]",
    "├──[sharedSecret]",
    "├──/",
    "│  │ # Plumber router with 5 endpoints, 4 filters, and 0 sub-routers.",
    "│  ├──[queryString]",
    "│  ├──[body]",
    "│  ├──[cookieParser]",
    "│  ├──[sharedSecret]",
    "│  ├──/ (GET, POST)",
    "│  ├──/nested",
    "│  │  └──/path (GET, POST)",
    "│  └──/something (POST)"
  )

  expect_equal(printed, expected_output)
})
