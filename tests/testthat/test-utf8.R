test_that("parseUTF8 has same srcfile attribute as file arg input", {
  filename <- test_path("files/plumber.R")
  expect_equal(attr(parseUTF8(filename), "srcfile")$filename, filename)
})
