context("block parsing")

test_that("trimws works", {
  expect_equal(trimws("    hi there \t  "), "hi there")
  expect_equal(trimws("hi there\t"), "hi there")
  expect_equal(trimws("hi "), "hi")
})

test_that("parseBlock works", {
  lines <- c(
    "#' @get /",
    "#' @post /",
    "#' @filter test",
    "#' @serializer json")
  b <- parseBlock(length(lines), lines)
  expect_equal(b$path, "/")
  expect_equal(b$verbs, c("POST", "GET"))
  expect_equal(b$filter, "test")
  expect_equal_functions(b$serializer, serializer_json())
})

test_that("parseBlock images", {
  lines <- c("#'@png")
  b <- parseBlock(length(lines), lines)
  expect_equal(b$image, "png")
  expect_equal(b$imageAttr, "")

  lines <- c("#'@jpeg")
  b <- parseBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "")

  # Whitespace is fine
  lines <- c("#' @jpeg    \t ")
  b <- parseBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "")

  # Properly formatted arguments work
  lines <- c("#'@jpeg (width=100)")
  b <- parseBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "(width=100)")

  # Ill-formatted arguments return a meaningful error
  lines <- c("#'@jpeg width=100")
  expect_error(parseBlock(length(lines), lines), "Supplemental arguments to the image serializer")
})

test_that("Block can't be multiple mutually exclusive things", {

  srcref <- c(3,4)
  addE <- function(){ fail() }
  addF <- function(){ fail() }
  addA <- function(){ fail() }
  expect_error({
    activateBlock(srcref, c("#' @get /", "#' @assets /", "function(){}"),
                  function(){}, addE, addF, addA)
  }, "A single function can only be")

})

# TODO: more testing around filter, assets, endpoint, etc.
