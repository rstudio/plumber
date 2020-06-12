context("Static")

# Windows-note. Convert all text to char and trim to avoid differences involving `\r\n` and `\n`

pr <- PlumberStatic$new(test_path("files/static"))

test_that("the response is returned", {
  res <- PlumberResponse$new()
  val <- pr$route(make_req("GET", "/test.txt"), res)
  expect_true(inherits(val, "PlumberResponse"))
})

test_that("static txt file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/test.txt"), res)
  expect_equal(res$headers$`Content-Type`, "text/plain")
  expect_equal(trimws(rawToChar(res$body)), "I am a text file.")
})

test_that("static html file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/index.html"), res)
  expect_equal(res$headers$`Content-Type`, "text/html; charset=UTF-8")
  expect_equal(trimws(rawToChar(res$body)), "<html>I am HTML</html>")
})

test_that("root requests are routed to index.html", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/"), res)
  expect_equal(res$headers$`Content-Type`, "text/html; charset=UTF-8")
  expect_equal(trimws(rawToChar(res$body)), "<html>I am HTML</html>")
})

test_that("static binary file is served", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/test.txt.zip"), res)
  expect_equal(res$headers$`Content-Type`, "application/octet-stream")
  bod <- res$body
  zipf <- file(test_path("files/static/test.txt.zip"), "rb")
  bin <- readBin(zipf, "raw", n=1000)
  close(zipf)
  expect_equal(bin, bod)
})

test_that("404s are handled", {
  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/i-dont-exist"), res)
  expect_equal(res$status, 404)
})

test_that("PUTs error", {
  res <- PlumberResponse$new()
  pr$route(make_req("PUT", "/"), res)
  expect_equal(res$status, 400)
})

test_that("files are parsed properly", {
  p <- plumber$new(test_path("files/static.R"))
  expect_length(p$mounts, 2)

  res <- PlumberResponse$new()
  req <- make_req("GET", "/static/test.txt")
  p$route(req=req, res=res)
  expect_equal(nchar(trimws(rawToChar(res$body))), 17)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-Type`, "text/plain")

  res <- PlumberResponse$new()
  req <- make_req("GET", "/public/test.txt")
  p$route(req=req, res=res)
  expect_equal(nchar(trimws(rawToChar(res$body))), 17)
  expect_equal(res$status, 200)
  expect_equal(res$headers$`Content-Type`, "text/plain")
})

test_that("no directory throws error", {
  expect_error(plumber$new(test_path("files/static-nodir.R")), "No directory specified")
})

test_that("expressions work as options", {
  pr <- plumber$new()
  stat <- PlumberStatic$new(test_path("files/static"), {list()})
  pr$mount("/public", stat)

  res <- PlumberResponse$new()
  pr$route(make_req("GET", "/public/test.txt"), res)
  expect_equal(res$headers$`Content-Type`, "text/plain")
  expect_equal(trimws(rawToChar(res$body)), "I am a text file.")
})
