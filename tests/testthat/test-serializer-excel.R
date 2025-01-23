context("excel serializer")

test_that("excel serializes properly", {
  skip_if_not_installed("writexl")

  d <- data.frame(a=1, b=2, c="hi")
  val <- serializer_excel()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  
  # the remaining relies on the fact that xlsx files start as zip files
  # https://en.wikipedia.org/wiki/List_of_file_signatures
  expect_equal(val$body[1:4], as.raw(c(0x50, 0x4b, 0x03, 0x04)))
  tf <- tempfile()
  on.exit(unlink(tf), add = TRUE)
  writeBin(val$body, tf)
  zipcontents <- expect_silent(utils::unzip(tf, list = TRUE))
  expect_s3_class(zipcontents, "data.frame")
  expect_true("xl/workbook.xml" %in% zipcontents$Name)

})

test_that("Errors call error handler", {
  skip_if_not_installed("writexl")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_excel()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), errorHandler = errHandler)
  expect_equal(errors, 1)
})
