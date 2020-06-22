context("POST body")

test_that("JSON is consumed on POST", {
  expect_equal(parseBody('{"a":"1"}', content_type = NULL), list(a = "1"))
})

test_that("ending in `==` does not produce a unexpected key", {
  # See https://github.com/rstudio/plumber/issues/463
  expect_equal(parseBody("randomcharshere==", content_type = NULL), list())
})

test_that("Query strings on post are handled correctly", {
  expect_equivalent(parseBody("a="), list()) # It's technically a named list()
  expect_equal(parseBody("a=1&b=&c&d=1", content_type = NULL), list(a="1", d="1"))
})

test_that("Able to handle UTF-8", {
  expect_equal(parseBody('{"text":"Ã©lise"}', content_type = "application/json; charset=UTF-8")$text, "Ã©lise")
})

#charset moved to part parsing
test_that("filter passes on content-type", {
  content_type_passed <- ""
  req <- list(
    .internal = list(postBodyHandled = FALSE),
    rook.input = list(
      read = function() {
        called <- TRUE
        return(charToRaw("this is a body"))
      },
      rewind = function() {},
      read_lines = function() {return("this is a body")}
    ),
    HTTP_CONTENT_TYPE = "text/html; charset=testset",
    args = c()
  )
  with_mock(
    parseBody = function(body, content_type = "unknown") {
      print(content_type)
      body
    },
    expect_output(postBodyFilter(req), "text/html; charset=testset"),
    .env = "plumber"
  )
})

# parsers
test_that("Test text parser", {
  expect_equal(parseBody("Ceci est un texte.", "text/html"), "Ceci est un texte.")
})

test_that("Test yaml parser", {
  skip_if_not_installed("yaml")

  r_object <- list(a=1,b=list(c=2,d=list(e=3,f=4:6)))
  expect_equal(parseBody(charToRaw(yaml::as.yaml(r_object)), "application/x-yaml"), r_object)
})

test_that("Test multipart parser", {

  bin_file <- test_path("files/multipart-form.bin")
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  parsed_body <- parseBody(body, "multipart/form-data; boundary=----WebKitFormBoundaryMYdShB9nBc32BUhQ")

  expect_equal(names(parsed_body), c("json", "img1", "img2", "rds"))
  expect_equal(parsed_body[["rds"]], women)
  expect_equal(attr(parsed_body[["img1"]], "filename"), "avatar2-small.png")
  expect_equal(parsed_body[["json"]], list(a=2,b=4,c=list(w=3,t=5)))
})
