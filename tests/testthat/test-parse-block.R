context("block parsing")

test_that("trimws works", {
  expect_equal(trimws("    hi there \t  "), "hi there")
  expect_equal(trimws("hi there\t"), "hi there")
  expect_equal(trimws("hi "), "hi")
})

test_that("plumbBlock works", {
  lines <- c(
    "#' @get /",
    "#' @post /",
    "#' @filter test",
    "#' @serializer json")
  b <- plumbBlock(length(lines), lines)
  expect_length(b$path, 2)
  expect_equal(b$path[[1]], list(verb="POST", path="/"))
  expect_equal(b$path[[2]], list(verb="GET", path="/"))
  expect_equal(b$filter, "test")

  # due to covr changing some code, the return answer is very strange
  # the tests below should be skipped on covr
  testthat::skip_on_covr()

  expect_equal_functions(b$serializer, serializer_json())
})

test_that("plumbBlock images", {
  lines <- c("#'@png")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$image, "png")
  expect_equal(b$imageAttr, "")

  lines <- c("#'@jpeg")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "")

  # Whitespace is fine
  lines <- c("#' @jpeg    \t ")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "")

  # No whitespace is fine
  lines <- c("#' @jpeg(w=1)")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "(w=1)")

  # Additional chars after name don't count as image tags
  lines <- c("#' @jpegs")
  b <- plumbBlock(length(lines), lines)
  expect_null(b$image)
  expect_null(b$imageAttr)

  # Properly formatted arguments work
  lines <- c("#'@jpeg (width=100)")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$image, "jpeg")
  expect_equal(b$imageAttr, "(width=100)")

  # Ill-formatted arguments return a meaningful error
  lines <- c("#'@jpeg width=100")
  expect_error(plumbBlock(length(lines), lines), "Supplemental arguments to the image serializer")
})

test_that("Block can't be multiple mutually exclusive things", {

  srcref <- c(3,4)
  addE <- function(){ fail() }
  addF <- function(){ fail() }
  addA <- function(){ fail() }
  expect_error({
    evaluateBlock(srcref, c("#' @get /", "#' @assets /", "function(){}"),
                  function(){}, addE, addF, addA)
  }, "A single function can only be")

})

test_that("Block can't contain duplicate tags", {
  lines <- c("#* @tag test",
            "#* @tag test")
  expect_error(plumbBlock(length(lines), lines), "Duplicate tag specified.")
})

test_that("@json parameters work", {

  # due to covr changing some code, the return answer is very strange
  testthat::skip_on_covr()

  expect_block_fn <- function(lines, fn) {
    b <- plumbBlock(length(lines), lines)
    expect_equal_functions(b$serializer, fn)
  }
  expect_block_error <- function(lines, ...) {
    expect_error({
      plumbBlock(length(lines), lines)
    }, ...)
  }

  expect_block_fn("#' @serializer json", serializer_json())
  expect_block_fn("#' @json", serializer_json())
  expect_block_fn("#' @json()", serializer_json())
  expect_block_fn("#' @serializer unboxedJSON", serializer_unboxed_json())

  expect_block_fn("#' @serializer json list(na = 'string')", serializer_json(na = 'string'))
  expect_block_fn("#' @json(na = 'string')", serializer_json(na = 'string'))

  expect_block_fn("#* @serializer unboxedJSON list(na = \"string\")", serializer_unboxed_json(na = 'string'))
  expect_block_fn("#' @json(auto_unbox = TRUE, na = 'string')", serializer_json(auto_unbox = TRUE, na = 'string'))


  expect_block_fn("#' @json (    auto_unbox = TRUE, na = 'string'    )", serializer_json(auto_unbox = TRUE, na = 'string'))
  expect_block_fn("#' @json (auto_unbox          =       TRUE    ,      na      =      'string'   )             ", serializer_json(auto_unbox = TRUE, na = 'string'))
  expect_block_fn("#' @serializer json list   (      auto_unbox          =       TRUE    ,      na      =      'string'   )             ", serializer_json(auto_unbox = TRUE, na = 'string'))


  expect_block_error("#' @serializer json list(na = 'string'", "unexpected end of input")
  expect_block_error("#' @json(na = 'string'", "must be surrounded by parentheses")
  expect_block_error("#' @json (na = 'string'", "must be surrounded by parentheses")
  expect_block_error("#' @json ( na = 'string'", "must be surrounded by parentheses")
  expect_block_error("#' @json na = 'string')", "must be surrounded by parentheses")
  expect_block_error("#' @json list(na = 'string')", "must be surrounded by parentheses")

})


test_that("@html parameters produce an error", {
  # due to covr changing some code, the return answer is very strange
  testthat::skip_on_covr()

  expect_block_fn <- function(lines, fn) {
    b <- plumbBlock(length(lines), lines)
    expect_equal_functions(b$serializer, fn)
  }
  expect_block_error <- function(lines, ...) {
    expect_error({
      plumbBlock(length(lines), lines)
    }, ...)
  }

  expect_block_fn("#' @serializer html", serializer_html())

  expect_block_fn("#' @serializer html list()", serializer_html())
  expect_block_fn("#' @serializer html list(         )", serializer_html())
  expect_block_fn("#' @serializer html list     (         )     ", serializer_html())

  expect_block_fn("#' @html", serializer_html())
  expect_block_fn("#' @html()", serializer_html())
  expect_block_fn("#' @html ()", serializer_html())
  expect_block_fn("#' @html ( )", serializer_html())
  expect_block_fn("#' @html ( ) ", serializer_html())
  expect_block_fn("#' @html         (       )       ", serializer_html())

  expect_block_error("#' @serializer html list(key = \"val\")", "unused argument")
  expect_block_error("#' @html(key = \"val\")", "unused argument")
  expect_block_error("#' @html (key = \"val\")", "unused argument")

  expect_block_error("#' @html (key = \"val\")", "unused argument")
})

# TODO: more testing around filter, assets, endpoint, etc.
