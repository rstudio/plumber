context("Images")

test_that("Images are properly rendered", {
  r <- plumber$new("files/image.R")

  resp <- r$serve(make_req("GET", "/png"), PlumberResponse$new())
  expect_equal(resp$status, 200)
  expect_equal(resp$headers$`Content-type`, "image/png")
  fullsizePNG <- length(resp$body)
  expect_gt(fullsizePNG, 1000) # This changes based on R ver/OS, may not be useful.

  resp <- r$serve(make_req("GET", "/littlepng"), PlumberResponse$new())
  expect_equal(resp$status, 200)
  expect_equal(resp$headers$`Content-type`, "image/png")
  expect_gt(length(resp$body), 100) # This changes based on R ver/OS, may not be useful.
  expect_lt(length(resp$body), fullsizePNG) # Should be smaller than the full one

  resp <- r$serve(make_req("GET", "/jpeg"), PlumberResponse$new())
  expect_equal(resp$status, 200)
  expect_equal(resp$headers$`Content-type`, "image/jpeg")
  fullsizeJPEG <- length(resp$body)
  expect_gt(fullsizeJPEG, 1000) # This changes based on R ver/OS, may not be useful.

  resp <- r$serve(make_req("GET", "/littlejpeg"), PlumberResponse$new())
  expect_equal(resp$status, 200)
  expect_equal(resp$headers$`Content-type`, "image/jpeg")
  expect_gt(length(resp$body), 100) # This changes based on R ver/OS, may not be useful.
  expect_lt(length(resp$body), fullsizeJPEG) # Should be smaller than the full one
})
