

test_that("as_attachment shape", {
  val <- as_attachment(iris, "name.csv")
  expect_s3_class(val, "plumber_attachment")
  expect_equal(val$value, iris)
  expect_equal(val$filename, "name.csv")
})

test_that("disposition is not added unless content type exists", {
  val <- as_attachment("<html><h1>Hi!</h1></html>")
  res <- serializer_headers(list(), identity)(val, list(), PlumberResponse$new(), stop)
  expect_null(res$headers$`Content-Disposition`)
})

test_that("disposition is not added unless content type exists", {
  val <- as_attachment("<html><h1>Hi!</h1></html>")
  res <- serializer_content_type("text/html; charset=UTF-8", identity)(val, list(), PlumberResponse$new(), stop)
  expect_equal(res$headers$`Content-Type`, "text/html; charset=UTF-8")
  expect_equal(res$headers$`Content-Disposition`, "attachment")
  expect_equal(res$body, val$value)
  expect_equal(res$status, 200L)
})

test_that("disposition file can not contain quotes", {
  val <- as_attachment("<html><h1>Hi!</h1></html>", filename = "quote\".csv")
  expect_error({
    serializer_content_type("text/html; charset=UTF-8", identity)(val, list(), PlumberResponse$new(), stop)
  })
  val <- as_attachment("<html><h1>Hi!</h1></html>", filename = "quote'.csv")
  expect_error({
    serializer_content_type("text/html; charset=UTF-8", identity)(val, list(), PlumberResponse$new(), stop)
  })
})

test_that("disposition is added", {
  val <- as_attachment("<html><h1>Hi!</h1></html>", filename = "dispo.html")
  res <- serializer_content_type("text/html; charset=UTF-8", identity)(val, list(), PlumberResponse$new(), stop)
  expect_equal(res$headers$`Content-Type`, "text/html; charset=UTF-8")
  expect_equal(res$headers$`Content-Disposition`,"attachment; filename=\"dispo.html\"")
  expect_equal(res$body, val$value)
  expect_equal(res$status, 200L)
})

test_that("disposition is not overwritten", {
  val <- as_attachment("<html><h1>Hi!</h1></html>", filename = "dispo.html")
  res <- serializer_headers(
    list(
      "Content-Type" = "text/html; charset=UTF-8",
      "Content-Disposition" = "attachment; filename=\"original.html\""
    ),
    identity
  )(val, list(), PlumberResponse$new(), stop)

  expect_equal(res$headers$`Content-Type`, "text/html; charset=UTF-8")
  expect_equal(res$headers$`Content-Disposition`,"attachment; filename=\"original.html\"")
  expect_equal(res$body, val$value)
  expect_equal(res$status, 200L)
})
