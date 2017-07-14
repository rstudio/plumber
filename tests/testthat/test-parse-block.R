context("block parsing")

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
  expect_equal_functions(b$serializer, jsonSerializer())
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
