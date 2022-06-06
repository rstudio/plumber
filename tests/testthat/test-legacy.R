
context("legacy")

test_that("postBody is still available", {
  r <- pr(test_path("files/legacy.R"))
  res <- PlumberResponse$new()

  test_body <- 'testing body\nline 2'

  expect_identical(
    r$route(make_req("POST", "/postBody", body = test_body), res),
    test_body
  )
})

test_that("postBody is not enabled by default", {

  skip_on_os("windows") # Windows does not like the null pointer / non-utf8 body

  bin_file <- test_path("files/multipart-form.bin")
  bin_body <- readBin(bin_file, "raw", file.info(bin_file)$size)

  req <- make_req(
    "POST", "/postBody",
    body = bin_body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=----WebKitFormBoundaryMYdShB9nBc32BUhQ"
  )

  r <- pr(test_path("files/legacy.R"))
  # when parsing a multipart file, null pointers don't behave well in strings
  expect_output({
    r$route(req, PlumberResponse$new())
  }, "embedded nul in string")

  req <- make_req(
    "POST", "/body",
    body = bin_body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=----WebKitFormBoundaryMYdShB9nBc32BUhQ"
  )
  # when parsing a multipart file, null pointers don't behave well in strings
  # So if `req$postBody` is not touched, there is no error.
  expect_silent({
    r$route(req, PlumberResponse$new())
  })

})
