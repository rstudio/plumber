context("Images")

test_image <- local({
    r <- plumber$new(test_path("files/image.R"))

  function(name, content_type, capability_type = name, test_little = TRUE) {
    if (!capabilities(capability_type)) {
      testthat::skip("Graphics type not supported: ", name)
    }

    resp <- r$serve(make_req("GET", paste0("/", name)), PlumberResponse$new())
    expect_equal(resp$status, 200)
    expect_equal(resp$headers$`Content-Type`, content_type)
    fullsize <- length(resp$body)
    expect_gt(fullsize, 1000) # This changes based on R ver/OS, may not be useful.

    if (!isTRUE(test_little)) {
      # do not test the smaller image route
      return()
    }
    resp <- r$serve(make_req("GET", paste0("/little", name)), PlumberResponse$new())
    expect_equal(resp$status, 200)
    expect_equal(resp$headers$`Content-Type`, content_type)
    expect_gt(length(resp$body), 100) # This changes based on R ver/OS, may not be useful.
    expect_lt(length(resp$body), fullsize) # Should be smaller than the full one
  }
})

test_that("png are properly rendered", {
  test_image("png", "image/png")
})
test_that("jpeg are properly rendered", {
  test_image("jpeg", "image/jpeg")
})
test_that("svg are properly rendered", {
  test_image("svg", "image/svg+xml", capability_type = "cairo", test_little = FALSE)
})

test_that("render_image arguments supplement", {
  pngcalls <- NULL
  mypng <- function(...){
    pngcalls <<- list(...)
  }

  p <- render_image(mypng, list(a=1, b=2))

  data <- new.env()
  req <- make_req("GET", "/")
  res <- list()
  p$preexec(req, res, data)
  expect_length(pngcalls, 3)
  expect_equal(pngcalls$filename, data$file)
  expect_equal(pngcalls$a, 1)
  expect_equal(pngcalls$b, 2)
})
