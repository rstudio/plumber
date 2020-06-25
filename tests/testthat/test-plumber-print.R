test_that("prints correctly", {
  testthat::skip_on_cran()
  testthat::skip_on_os("windows") # has issues comparing text values


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

  expected_output <- c(
    "# Plumber router with 2 endpoints, 4 filters, and 2 sub-routers.",
    "# Call run() on this object to start the API.",
    "├──[queryString]",
    "├──[postBody]",
    "├──[cookieParser]",
    "├──[sharedSecret]",
    "├──/nested",
    "│  ├──/path",
    "│  │  └──/here (GET, POST)",
    "├──/mysubpath",
    "│  │ # Plumber router with 2 endpoints, 4 filters, and 0 sub-routers.",
    "│  ├──[queryString]",
    "│  ├──[postBody]",
    "│  ├──[cookieParser]",
    "│  ├──[sharedSecret]",
    "│  ├──/ (GET)",
    "│  └──/something (POST)",
    "├──/static",
    "│  │ # Plumber static router serving from directory: ."
  )

  expect_equal(printed, expected_output)
})

test_that("prints correctly", {
  testthat::skip_on_cran()
  testthat::skip_on_os("windows") # has issues comparing text values

  pr <- plumber$new()
  sub <- plumber$new()
  sub$handle("GET", "/", force)
  sub$handle("POST", "/something", force)
  sub$handle("GET", "/nested/path", force)
  sub$handle("POST", "/", force)
  sub$handle("POST", "/nested/path", force)

  pr$mount("/", sub)

  printed <- capture.output(print(pr))

  expected_output <- c(
    "# Plumber router with 0 endpoints, 4 filters, and 1 sub-router.",
    "# Call run() on this object to start the API.",
    "├──[queryString]",
    "├──[postBody]",
    "├──[cookieParser]",
    "├──[sharedSecret]",
    "├──/",
    "│  │ # Plumber router with 5 endpoints, 4 filters, and 0 sub-routers.",
    "│  ├──[queryString]",
    "│  ├──[postBody]",
    "│  ├──[cookieParser]",
    "│  ├──[sharedSecret]",
    "│  ├──/ (GET, POST)",
    "│  ├──/something (POST)",
    "│  ├──/nested",
    "│  │  └──/path (GET, POST)"
  )

  expect_equal(printed, expected_output)
  # for (i in 1:length(regexps)){
  #   expect_match(printed[i], regexps[i], info=paste0("on line ", i), fixed = TRUE)
  # }

})
