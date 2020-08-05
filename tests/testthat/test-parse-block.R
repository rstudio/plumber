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
  expect_length(b$paths, 2)
  expect_equal(b$paths[[1]], list(verb="POST", path="/"))
  expect_equal(b$paths[[2]], list(verb="GET", path="/"))
  expect_equal(b$filter, "test")

  # due to covr changing some code, the return answer is very strange
  # the tests below should be skipped on covr
  testthat::skip_on_covr()

  expect_equal_functions(b$serializer, serializer_json())
})

test_that("plumbBlock images", {
  lines <- c("#'@png")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_png())

  lines <- c("#'@jpeg")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_jpeg())
  lines <- c("#'@png")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_png())

  # Whitespace is fine
  lines <- c("#' @jpeg    \t ")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_jpeg())

  # No whitespace is fine
  lines <- c("#' @jpeg(w=1)")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_jpeg(w=1))

  # Additional chars after name don't count as image tags
  lines <- c("#' @jpegs")
  expect_error(
    expect_warning({plumbBlock(length(lines), lines)}),
    "Supplemental arguments to the serializer"
  )

  # Properly formatted arguments work
  lines <- c("#'@jpeg (width=100)")
  expect_warning({
    b <- plumbBlock(length(lines), lines)
  })
  expect_equal(b$serializer, serializer_jpeg(width = 100))

  # Ill-formatted arguments return a meaningful error
  lines <- c("#'@jpeg width=100")
  expect_error(
    expect_warning({plumbBlock(length(lines), lines)}),
    "Supplemental arguments to the serializer"
  )
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

  plumb_block_check <- function(lines) {
    if (grepl("@json", lines, fixed = TRUE)) {
      expect_warning(
        plumbBlock(length(lines), lines)
      )
    } else {
      plumbBlock(length(lines), lines)
    }
  }
  expect_block_fn <- function(lines, fn) {
    expect_equal_functions(plumb_block_check(lines)$serializer, fn)
  }
  expect_block_error <- function(lines, ...) {
    expect_error({
      plumb_block_check(lines)
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

  plumb_block_check <- function(lines) {
    if (grepl("@html", lines, fixed = TRUE)) {
      expect_warning(
        plumbBlock(length(lines), lines)
      )
    } else {
      plumbBlock(length(lines), lines)
    }
  }
  expect_block_fn <- function(lines, fn) {
    expect_equal_functions(plumb_block_check(lines)$serializer, fn)
  }
  expect_block_error <- function(lines, ...) {
    expect_error({
      plumb_block_check(lines)
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

test_that("@parser parameters produce an error or not", {
  # due to covr changing some code, the return answer is very strange
  testthat::skip_on_covr()

  expect_block_parser <- function(lines, fn) {
    b <- plumbBlock(length(lines), lines)
    expect_equal(b$parsers, fn)
  }
  expect_block_error <- function(lines, ...) {
    expect_error({
      plumbBlock(length(lines), lines)
    }, ...)
  }


  expected <- list(octet = list())
  expect_block_parser("#' @parser octet",  expected)

  expect_block_parser("#' @parser octet list()", expected)
  expect_block_parser("#' @parser octet list(         )", expected)
  expect_block_parser("#' @parser octet list     (         )     ", expected)

  expect_error({
    evaluateBlock(
      srcref = 3, # which evaluates to line 2
      file = c("#' @get /test", "#' @parser octet list(key = \"val\")"),
      expr = substitute(identity),
      envir = new.env(),
      addEndpoint = function(a, b, ...) { stop("should not reach here")},
      addFilter = as.null,
      pr = plumber$new()
    )
  }, "unused argument (key = \"val\")", fixed = TRUE)
})
test_that("Plumbing block use the right environment", {
  expect_silent(plumb(test_path("files/plumb-envir.R")))
})


test_that("device serializers produce a structure", {
  # due to covr changing some code, the return answer is very strange
  testthat::skip_on_covr()

  expect_s3_block <- function(lines, serializer_fn) {
    block <- plumbBlock(length(lines), lines)
    expect_s3_class(block$serializer, "plumber_endpoint_serializer")
    serializer_info <- serializer_fn()
    expect_equal(block$serializer$serializer, serializer_info$serializer)
    expect_true(is.function(block$serializer$serializer))
    expect_equal(block$serializer$hooks, serializer_info$hooks)
    expect_true(all(c("preexec", "postexec") %in% names(block$serializer$hooks)))
  }

  expect_s3_block("#' @serializer jpeg", serializer_jpeg)
  expect_s3_block("#' @serializer png", serializer_png)
  expect_s3_block("#' @serializer svg", serializer_svg)
  expect_s3_block("#' @serializer bmp", serializer_bmp)
  expect_s3_block("#' @serializer tiff", serializer_tiff)
  expect_s3_block("#' @serializer pdf", serializer_pdf)
})

# TODO: more testing around filter, assets, endpoint, etc.
