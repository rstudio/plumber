# Manual Tests!!
library(testthat)
library(plumber)






test_that("custom OpenAPI Specification update function works", {
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




test_that("host doesn't change for messages, but does for RStudio IDE", {

  pr <- plumb(system.file("examples/01-append/plumber.R", package = "plumber"))

  pr$run(
    "0.0.0.0", port = 1234
  )
  #> Running plumber API at http://0.0.0.0:1234
  #> Running Swagger UI  at http://127.0.0.1:1234/__swagger__/

  pr$run(
    "::", port = 1234
  )
  #> Running plumber API at http://[::]:1234
  #> Running Swagger UI  at http://[::1]:1234/__swagger__/


  # Verify that the output matches the output above.
  # if in RStudio IDE, verify that the window opened, opens to http://127.0.0.1:1234/__swagger__/ or http://[::1]:1234/__swagger__/
  # verify that the swagger route (from messages) works in a web browser http://127.0.0.1:1234/__swagger__/ or http://[::1]:1234/__swagger__/
  # Verify that http://0.0.0.0/tail or http://[::1]:1234/tail executes
})
