context("Plumber Environment")

test_that(
  "Variables are populated in local environment, even if created after functions that use them",
  {
    r <- plumber$new(test_path("files/source_values.R"))

    errors <- 0
    notFounds <- 0
    errRes <- list(a=1)
    notFoundRes <- list(b=2)
    r$setErrorHandler(function(req, res, err){ errors <<- errors + 1; errRes })
    r$set404Handler(function(req, res){ notFounds <<- notFounds + 1; notFoundRes })

    res <- PlumberResponse$new()

    expected <- "value_a"
    expect_equal(r$route(make_req("GET", "/count"), res), 1)
    expect_equal(r$route(make_req("GET", "/static_count"), res), 1)

    expect_equal(errors, 0)
    expect_equal(notFounds, 0)
  }
)
