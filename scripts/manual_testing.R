# Manual Tests!!
library(testthat)
library(plumber)






test_that("custom swagger file update function works", {
  pr <- plumber$new()
  pr$handle("GET", "/:path/here", function(){})

  pr$run(
    port = 1234,
    swagger = function(pr_, spec, ...) {
      spec$info$title <- Sys.time()
      spec
    }
  )

  # validate that http://127.0.0.1:1234/__swagger__/ displays the system time as the api title
  # http://127.0.0.1:1234/__swagger__/
})
