make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Includes work", {
  r <- plumber$new("files/includes.R")

  # When running, we setwd to the file's dir. Simulate that here.
  cwd <- getwd()
  on.exit( { setwd(cwd) } )
  setwd("files")

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/"), res)
  expect_equal(val$body, "test.txt content")
  expect_equal(val$headers$`Content-type`, NULL)

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/html"), res)
  expect_match(val$body, ".*<html.*</html>\\s*$")
  expect_equal(val$headers$`Content-type`, "text/html; charset=utf-8")

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/md"), res)
  expect_match(val$body, "<html.*<h2>R Output</h2>.*</html>\\s*$")
  expect_equal(val$headers$`Content-type`, "text/html; charset=utf-8")

  res <- PlumberResponse$new()
  val <- r$route(make_req("GET", "/rmd"), res)
  expect_match(val$body, "<html.*<img src=\"data:image/png;base64.*</html>\\s*$")
  expect_equal(val$headers$`Content-type`, "text/html; charset=utf-8")
})
