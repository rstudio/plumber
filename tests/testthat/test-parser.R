context("Parsers tag")

test_that("parsers can be combined", {

  expect_parsers <- function(names, target_names, sort_items = TRUE) {
    aliases <- names(make_parser(names)$alias)
    if (sort_items) {
      aliases <- sort(aliases)
      target_names <- sort(target_names)
    }
    expect_equal(aliases, target_names)
  }

  expect_parsers("json", "json")

  expect_parsers(c("form", "json"), c("form", "json"), sort_items = FALSE)

  expect_parsers("all", setdiff(registered_parsers(), c("all", "none")))
  expect_parsers(list(all = list()), setdiff(registered_parsers(), c("all", "none")))
  expect_parsers(TRUE, setdiff(registered_parsers(), c("all", "none")))



  # make sure parameters are not overwritten even when including all
  parsers_plain <- make_parser(list(all = list(), json = list(simplifyVector = FALSE)))
  json_input <- parsers_plain$alias$json(charToRaw(jsonlite::toJSON(1:3)))
  expect_equal(json_input, list(1,2,3))

  parsers_guess <- make_parser(list(all = list(), json = list(simplifyVector = TRUE)))
  json_input <- parsers_guess$alias$json(charToRaw(jsonlite::toJSON(1:3)))
  expect_equal(json_input, c(1,2,3))

  # check that parsers return already combined parsers
  expect_equal(make_parser(parsers_plain), parsers_plain)
})

test_that("parsers work", {
  r <- plumber$new(test_path("files/parsers.R"))
  res <- PlumberResponse$new()

  expect_identical(r$route(make_req("POST", "/default", body='{"a":1}'), res), structure(list(1L), names = "a"))
  expect_identical(r$route(make_req("POST", "/none", body='{"a":1}'), res), structure(list(), names = character()))
  expect_identical(r$route(make_req("POST", "/all", body='{"a":1}'), res), structure(list(1L), names = "a"))
  bin_file <- test_path("files/multipart-ctype.bin")
  bin_body <- readBin(bin_file, "raw", file.info(bin_file)$size)
  expect_identical(r$route(make_req("POST", "/none", body=rawToChar(bin_body)), res), structure(list(), names = character()))
  expect_message(r$route(make_req("POST", "/json", body=rawToChar(bin_body)), res), "No suitable parser found")

  bin_file <- test_path("files/multipart-form.bin")
  bin_body <- readBin(bin_file, "raw", file.info(bin_file)$size)


  req <- new.env()
  req$REQUEST_METHOD <- "POST"
  req$PATH_INFO <- "/all"
  req$QUERY_STRING <- ""
  req$HTTP_CONTENT_TYPE <- "multipart/form-data; boundary=----WebKitFormBoundaryMYdShB9nBc32BUhQ"
  req$rook.input <- list(read_lines = function(){ stop("should not be executed") },
                         read = function(){ bin_body },
                         rewind = function(){ length(bin_body) })

  parsed_body <-
    local({
      op <- options(plumber.postBody = FALSE)
      on.exit({options(op)}, add = TRUE)
      r$route(req, PlumberResponse$new())
    })
  expect_equal(names(parsed_body), c("json", "img1", "img2", "rds"))
  expect_equal(parsed_body[["rds"]], women)
  expect_equal(names(parsed_body[["img1"]]), c("avatar2-small.png"))
  expect_true(is.raw(parsed_body[["img1"]][["avatar2-small.png"]]))
  expect_equal(parsed_body[["json"]], list(a=2,b=4,c=list(w=3,t=5)))


  # expect parsers match
  expect_equal(r$routes$none$parsers, make_parser("none"))
  expect_equal(r$routes$all$parsers, make_parser("all"))
  expect_equal(r$routes$default$parsers, NULL)
  expect_equal(r$routes$json$parsers, make_parser("json"))
  expect_equal(r$routes$mixed$parsers, make_parser(c("json", "form")))
  expect_equal(r$routes$repeated$parsers, make_parser("json"))
})
