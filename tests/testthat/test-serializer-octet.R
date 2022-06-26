test_that("octet serializes raw objects properly", {

  content <- charToRaw("Beware of bugs in the above code; I have only proved it correct, not tried it.")

  val <- serializer_octet()(content, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/octet-stream")
  expect_equal(val$body, content)
  expect_equal(rawToChar(val$body), rawToChar(content))
})

test_that("octet throws on non-raw objects", {

  content <- "Beware of bugs in the above code; I have only proved it correct, not tried it."

  expect_error(
    serializer_octet()(
      content,
      list(),
      PlumberResponse$new(),
      function(req, res, err) stop(err)
    ),
    "received non-raw data",
  )
})
