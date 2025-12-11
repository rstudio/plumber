context("Includes")

test_that("Includes work", {
  skip_if_not_installed("rmarkdown")

  r <- pr(test_path("files/includes.R"))

  # When running, we setwd to the file's dir. Simulate that here.
  cwd <- getwd()
  on.exit({
    setwd(cwd)
  })
  setwd(test_path("files"))

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/"), res)
  expect_equal(val$body, "test.txt content")
  expect_equal(val$headers$`Content-Type`, "text/plain")

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/html"), res)
  expect_match(val$body, ".*<html.*</html>\\s*$")
  expect_equal(val$headers$`Content-Type`, "text/html; charset=UTF-8")

  # Skip these tests on some CRAN instances
  if (rmarkdown::pandoc_available()) {
    res <- PlumberResponse$new()
    val <- r$route(make_req("GET", "/md"), res)
    expect_match(val$body, "<html.*<h2>R Output</h2>.*</html>\\s*$")
    expect_equal(val$headers$`Content-Type`, "text/html; charset=UTF-8")

    res <- PlumberResponse$new()
    val <- r$route(make_req("GET", "/rmd"), res)
    expect_match(val$body, "<html.*<img (role=\"img\" )?src=\"data:image/png;base64.*</html>\\s*$")
    expect_equal(val$headers$`Content-Type`, "text/html; charset=UTF-8")
  }
})
