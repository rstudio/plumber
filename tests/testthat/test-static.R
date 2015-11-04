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

test_that("files are parsed properly", {
  p <- plumber$new("files/static.R")
  staticFilt <- p$filters[grep("static-asset", sapply(p$filters, "[[", "name"))]
  expect_equal(length(staticFilt), 4)

  expect_equal(staticFilt[[1]]$lines, c(2,2))
  res <- PlumberResponse$new()
  req <- list(`PATH_INFO`="/static/test.txt", `REQUEST_METHOD`="GET")
  staticFilt[[1]]$exec(req=req, res=res)
  expect_equal(length(res$body), 18)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-type`, "text/plain")

  expect_equal(staticFilt[[2]]$lines, c(5,5))
  res <- PlumberResponse$new()
  req <- list(`PATH_INFO`="/static/test.txt", `REQUEST_METHOD`="GET")
  staticFilt[[2]]$exec(req=req, res=res)
  expect_equal(length(res$body), 18)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-type`, "text/plain")

  expect_equal(staticFilt[[3]]$lines, c(8,8))
  res <- PlumberResponse$new()
  req <- list(`PATH_INFO`="/public/test.txt", `REQUEST_METHOD`="GET")
  staticFilt[[3]]$exec(req=req, res=res)
  expect_equal(length(res$body), 18)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-type`, "text/plain")

  expect_equal(staticFilt[[4]]$lines, c(11,13))
  res <- PlumberResponse$new()
  req <- list(`PATH_INFO`="/public/test.txt", `REQUEST_METHOD`="GET")
  staticFilt[[4]]$exec(req=req, res=res)
  expect_equal(length(res$body), 18)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-type`, "text/plain")
})

test_that("no directory throws error", {
  expect_error(plumber$new("files/static-nodir.R"), "No directory specified")
})

test_that("expressions work as options", {
  pr <- plumber$new()
  pr$addAssets("files/static", "/public", {list()})

  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public/test.txt"), res)
  expect_equal(res$headers$`Content-type`, "text/plain")
  expect_equal(rawToChar(res$body), "I am a text file.\n")
})
