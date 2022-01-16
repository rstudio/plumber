context("parquet serializer")

test_that("parquet serializes properly", {
  skip_if_not_installed("arrow")

  d <- data.frame(a=1, b=2, c="hi")
  val <- serializer_parquet()(d, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/parquet")

  # can test  by doing a full round trip if we believe the parser works via `test-parse-body.R`
  parsed <- parse_body(val$body, "application/parquet", make_parser("parquet"))
  # convert from parquet tibble to data.frame
  parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  attr(parsed, "spec") <- NULL

  expect_equal(parsed, d)
})

test_that("Errors call error handler", {
  skip_if_not_installed("arrow")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_parquet()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), errorHandler = errHandler)
  expect_equal(errors, 1)
})

test_that("Errors are rendered correctly with debug TRUE", {
  skip_if_not_installed("arrow")

  pr <- pr() %>% pr_get("/", function() stop("myerror"), serializer = serializer_parquet()) %>% pr_set_debug(TRUE)
  capture.output(res <- pr$serve(make_req(pr = pr), PlumberResponse$new("csv")))

  expect_match(res$body, "Error in (function () : myerror", fixed = TRUE)
})
