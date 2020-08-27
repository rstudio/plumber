context("POST body")

test_that("JSON is consumed on POST", {
  expect_equal(parse_body('{"a":"1"}', content_type = NULL, parsers = make_parser("json")), list(a = "1"))
  expect_equal(parse_body('[1,2,3]', content_type = NULL, parsers = make_parser("json")), 1:3)
})

test_that("ending in `==` does not produce a unexpected key", {
  # See https://github.com/rstudio/plumber/issues/463
  expect_equal(parse_body("randomcharshere==", content_type = NULL, parsers = make_parser("form")), list())
})

test_that("Form query strings on post are handled correctly", {
  expect_equivalent(parse_body("a=", parsers = make_parser("form")), list()) # It's technically a named list()
  expect_equal(parse_body("a=1&b=&c&d=1", content_type = NULL, make_parser("form")), list(a="1", d="1"))
})

test_that("Able to handle UTF-8", {
  expect_equal(parse_body('{"text":"Ã©lise"}', content_type = "application/json", parsers = make_parser("json"))$text, "Ã©lise")
})

#charset moved to part parsing
test_that("filter passes on content-type", {
  req <- make_req(
    body = "this is a body",
    HTTP_CONTENT_TYPE = "text/html; charset=testset",
  )
  with_mock(
    parse_body = function(body, content_type = "unknown", parsers = NULL) {
      print(content_type)
      body
    },
    expect_output(body_parser(req, make_parser("text")), "text/html; charset=testset"),
    .env = "plumber"
  )
})

# parsers
test_that("Test text parser", {
  expect_equal(parse_body("Ceci est un texte.", "text/html", make_parser("text")), "Ceci est un texte.")
})

test_that("Test yaml parser", {
  skip_if_not_installed("yaml")

  r_object <- list(a=1,b=list(c=2,d=list(e=3,f=4:6)))
  expect_equal(parse_body(charToRaw(yaml::as.yaml(r_object)), "application/x-yaml", make_parser("yaml")), r_object)
})

test_that("Test csv parser", {
  skip_if_not_installed("readr")

  tmp <- tempfile()
  on.exit({
    file.remove(tmp)
  }, add = TRUE)

  r_object <- cars
  write.csv(r_object, tmp, row.names = FALSE)
  val <- readBin(tmp, "raw", 1000)

  parsed <- parse_body(val, "application/csv", make_parser("csv"))
  # convert from readr tibble to data.frame
  parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  attr(parsed, "spec") <- NULL

  expect_equal(parsed, r_object)
})

test_that("Test tsv parser", {
  skip_if_not_installed("readr")

  tmp <- tempfile()
  on.exit({
    file.remove(tmp)
  }, add = TRUE)

  r_object <- cars
  write.table(r_object, tmp, sep = "\t", row.names = FALSE)
  val <- readBin(tmp, "raw", 1000)

  parsed <- parse_body(val, "application/tab-separated-values", make_parser("tsv"))
  # convert from readr tibble to data.frame
  parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  attr(parsed, "spec") <- NULL

  expect_equal(parsed, r_object)
})

test_that("Test feather parser", {
  skip_if_not_installed("feather")

  tmp <- tempfile()
  on.exit({
    file.remove(tmp)
  }, add = TRUE)

  r_object <- iris
  feather::write_feather(r_object, tmp)
  val <- readBin(tmp, "raw", 10000)

  parsed <- parse_body(val, "application/feather", make_parser("feather"))
  # convert from feather tibble to data.frame
  parsed <- as.data.frame(parsed, stringsAsFactors = FALSE)
  attr(parsed, "spec") <- NULL

  expect_equal(parsed, r_object)
})


test_that("Test multipart output is reduced for argument matching", {
  bin_file <- test_path("files/multipart-file-names.bin")
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  req <- make_req(
    body = body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=---------------------------286326291134907228894146459692"
  )
  parsed_body <- body_parser(req, make_parser(c("multi", "octet", "json")))

  expect_s3_class(req$body, "plumber_multipart")
  expect_equal(names(req$body), c("files", "files", "files", "files", "dt", "namedval", "namedval", "namedval", "namedval"))
  for(part in req$body) {

    expect_equal(part$content_disposition, "form-data")
    expect_true(is.character(part$name))
    expect_true(is.raw(part$value))

    if (part$name == "dt") {
      expect_true(is.null(part$content_type))
    } else {
      expect_true(!is.null(part$content_type))
    }

    if (part$name == "dt" || identical(part$filename, "has_name3.json")) {
      expect_equal(part$parsed, jsonlite::parse_json("{}"))
    } else {
      expect_true(is.raw(part$parsed))
    }
  }

  expect_true(!inherits(parsed_body, "plumber_multipart"))
  expect_equal(names(parsed_body), c("files", "files", "files", "files", "dt", "namedval", "namedval", "namedval", "namedval"))
  lapply(seq_along(parsed_body), function(i) {
    parsed <- parsed_body[[i]]
    if (i %in% c(5, 9)) {
      expect_equal(parsed, jsonlite::parse_json("{}"))
    } else {
      expect_true(is.raw(parsed))
    }
  })
})


test_that("Test multipart parser", {
  # also tests rds and the octet -> content type conversion

  bin_file <- test_path("files/multipart-form.bin")
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  req <- make_req(
    body = body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=----WebKitFormBoundaryMYdShB9nBc32BUhQ"
  )
  parsed_body <- body_parser(req, make_parser(c("multi", "json", "rds", "octet")))

  expect_s3_class(req$body, "plumber_multipart")
  expect_equal(names(req$body), c("json", "img1", "img2", "rds"))
  for(part in req$body) {
    expect_equal(part$content_disposition, "form-data")
    expect_true(is.character(part$name))
    expect_true(is.raw(part$value))

    if (part$name == "json") {
      expect_true(is.null(part$content_type))
    } else {
      expect_true(!is.null(part$content_type))
    }

    switch(part$name,
      "json" = expect_equal(part$parsed, list(a=2,b=4,c=list(w=3,t=5))),
      "rds" = expect_equal(part$parsed, women),
      {
        if (part$name == "img1") expect_equal(part$filename, "avatar2-small.png")
        if (part$name == "img2") expect_equal(part$filename, "ragnarok_small.png")
        expect_true(is.raw(part$parsed))
        expect_gt(length(part$parsed), 100)
      }
    )
  }

  expect_true(!inherits(parsed_body, "plumber_multipart"))
  expect_equal(names(parsed_body), c("json", "img1", "img2", "rds"))
  expect_equal(parsed_body[["rds"]], women)
  expect_true(is.raw(parsed_body[["img1"]]))
  expect_gt(length(parsed_body[["img1"]]), 100)
  expect_true(is.raw(parsed_body[["img2"]]))
  expect_gt(length(parsed_body[["img2"]]), 100)
  expect_equal(parsed_body[["json"]], list(a=2,b=4,c=list(w=3,t=5)))
})


test_that("Test multipart respect content-type", {
  skip_if_not_installed("readr")

  bin_file <- test_path("files/multipart-ctype.bin")
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  req <- make_req(
    body = body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=---------------------------90908882332870323642673870272"
  )
  parsed_body <- body_parser(req, make_parser(c("multi", "tsv")))

  expect_s3_class(req$body, "plumber_multipart")
  expect_equal(length(req$body), 1)
  expect_equal(names(req$body), "sample_name")

  expect_equal(req$body$sample_name$content_disposition, "form-data")
  expect_true(is.character(req$body$sample_name$name))
  expect_true(is.raw(req$body$sample_name$value))
  expect_equal(req$body$sample_name$content_type, "text/tab-separated-values")

  expect_s3_class(req$body$sample_name$parsed, "data.frame")
  expect_equal(colnames(req$body$sample_name$parsed), c("x", "y", "z"))
  expect_equal(nrow(req$body$sample_name$parsed), 11)

  expect_true(!inherits(parsed_body, "plumber_multipart"))
  expect_s3_class(parsed_body$sample_name, "data.frame")
  expect_equal(colnames(parsed_body$sample_name), c("x", "y", "z"))
  expect_equal(nrow(parsed_body$sample_name), 11)
})

test_that("Test an array of files upload", {
  bin_file <- test_path("files/multipart-files-array.bin")
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  body <- readBin(bin_file, what = "raw", n = file.info(bin_file)$size)
  req <- make_req(
    body = body,
    HTTP_CONTENT_TYPE = "multipart/form-data; boundary=---------------------------286326291134907228894146459692"
  )
  parsed_body <- body_parser(req, make_parser(c("multi", "octet", "json")))

  expect_s3_class(req$body, "plumber_multipart")
  expect_equal(names(req$body), c("files", "files", "files", "files", "dt"))

  for(i in seq_along(req$body)) {
    part <- req$body[[i]]
    expect_equal(part$content_disposition, "form-data")
    expect_true(is.character(part$name))
    expect_true(is.raw(part$value))

    if (i == 1) {
      expect_equal(part$name, "files")
      expect_equal(part$filename, "avatar2-small.png")
      expect_equal(part$content_type, "image/png")
    } else if (i == 5) {
      expect_equal(part$name, "dt")
      expect_equal(part$content_type, NULL)
      expect_equal(part$parsed, jsonlite::parse_json("{}"))
    } else {
      expect_equal(part$name, "files")
      expect_equal(part$filename, paste0("text", i - 1, ".bin"))
      expect_equal(part$content_type, "application/octet-stream")
      expect_equal(rawToChar(part$parsed), letters[i - 1])
    }
  }

  expect_true(!inherits(parsed_body, "plumber_multipart"))
  expect_equal(names(parsed_body), c("files", "files", "files", "files", "dt"))
  expect_equal(rawToChar(parsed_body[[2]]), "a")
  expect_equal(rawToChar(parsed_body[[3]]), "b")
  expect_equal(rawToChar(parsed_body[[4]]), "c")
  expect_equal(parsed_body$dt, jsonlite::parse_json("{}"))
})
