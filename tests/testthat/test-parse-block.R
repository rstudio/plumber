context("block parsing")

test_that("trimws works", {
  expect_equal(trimws("    hi there \t  "), "hi there")
  expect_equal(trimws("hi there\t"), "hi there")
  expect_equal(trimws("hi "), "hi")
})

test_that("plumbBlock works", {
  lines <- c(
    "#* Plumber comment not reached",
    "NULL",
    "#* Plumber comments",
    "#* Plumber description",
    "#* second line",
    "",
    "  ",
    "# Normal comments",
    "#' @get /",
    "#' @post /",
    "#' @filter test",
    "#' @serializer json")
  b <- plumbBlock(length(lines), lines)
  expect_length(b$paths, 2)
  # Paths order follow original code
  expect_equal(b$paths[[1]], list(verb="GET", path="/"))
  expect_equal(b$paths[[2]], list(verb="POST", path="/"))
  expect_equal(b$filter, "test")
  expect_equal(b$comments, "Plumber comments")
  expect_equal(b$description, "Plumber description second line")

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
  expect_equal(b$serializer, serializer_jpeg(w=1), check.environment=FALSE)

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
  expect_equal(b$serializer, serializer_jpeg(width = 100), check.environment=FALSE)

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
      expr = as.expression(substitute(identity)),
      envir = new.env(),
      addEndpoint = function(a, b, ...) { stop("should not reach here")},
      addFilter = as.null,
      pr = pr()
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
    expect_equal(block$serializer$preexec_hook, serializer_info$preexec_hook)
    expect_equal(block$serializer$postexec_hook, serializer_info$postexec_hook)
  }

  expect_s3_block("#' @serializer jpeg", serializer_jpeg)
  expect_s3_block("#' @serializer png", serializer_png)
  expect_s3_block("#' @serializer svg", serializer_svg)
  expect_s3_block("#' @serializer bmp", serializer_bmp)
  expect_s3_block("#' @serializer tiff", serializer_tiff)
  expect_s3_block("#' @serializer pdf", serializer_pdf)
})

test_that("Tags can contains space", {
  lines <- c("#* @tag 'test space'",
             "#* @tag \"test space2\"")
  expect_equal(plumbBlock(length(lines), lines)$tags, c("test space", "test space2"))
})

test_that("single character tag and response", {
  lines <- c(
    "#' @tag a",
    "#' @response 2 b",
    "#' @response 4 b c")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$tags, "a")
  expect_equal(b$responses, list(`2` = list(description = "b"), `4` = list(description = "b c")))
})

test_that("block respect original order of lines for comments, tags and responses", {
  lines <- c(
    "#' @tag aaa",
    "#' @tag bbb",
    "#' comments first line",
    "#' comments second line",
    "#' comments third line",
    "#' @response 200 ok",
    "#' @response 404 not ok")
  b <- plumbBlock(length(lines), lines)
  expect_equal(b$description, "comments second line comments third line")
  expect_equal(b$tags, c("aaa", "bbb"))
  expect_equal(b$responses, list(`200`=list(description="ok"), `404` = list(description="not ok")))
})

test_that("srcref values are set while plumbing from a file", {

  root <- plumb_api("plumber", "01-append")
  endpt <- root$endpoints[[1]][[1]]
  expect_s3_class(endpt$srcref, "srcref")

  root_with_no_srcref <- pr() %>% pr_get("/", force)
  endpt_with_no_srcref <- root_with_no_srcref$endpoints[[1]][[1]]
  expect_equal(endpt_with_no_srcref$srcref, NULL)
})


# TODO: more testing around filter, assets, endpoint, etc.
