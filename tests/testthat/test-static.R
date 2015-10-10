make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

context("static")

pr <- plumber$new()
pr$addAssets("files/static", "/public")
pr$addAssets("files/static", "/public2")

test_that("static txt file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public/test.txt"), res)
  expect_equal(res$headers$`Content-type`, "text/plain")
  expect_equal(rawToChar(res$body), "I am a text file.\n")
})

test_that("static html file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public/index.html"), res)
  expect_equal(res$headers$`Content-type`, "text/html; charset=UTF-8")
  expect_equal(rawToChar(res$body), "<html>I am HTML</html>\n")
})

test_that("root requests are routed to index.html", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public/"), res)
  expect_equal(res$headers$`Content-type`, "text/html; charset=UTF-8")
  expect_equal(rawToChar(res$body), "<html>I am HTML</html>\n")
})

test_that("static binary file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public2/test.txt.zip"), res)
  expect_equal(res$headers$`Content-type`, "application/octet-stream")
  bod <- res$body
  bin <- readBin(file("files/static/test.txt.zip", "rb"), "raw", n=1000)
  expect_equal(bin, bod)
})

test_that("path prefix is accounted for", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public2/test.txt"), res)
  expect_equal(res$headers$`Content-type`, "text/plain")
  expect_equal(rawToChar(res$body), "I am a text file.\n")
})


