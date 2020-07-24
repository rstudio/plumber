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

  expect_parsers(c("query", "json"), c("query", "json"), sort_items = FALSE)

  expect_parsers("all", setdiff(registered_parsers(), c("all", "none")))
  expect_parsers(TRUE, setdiff(registered_parsers(), c("all", "none")))
  expect_parsers(list(all = list()), setdiff(registered_parsers(), c("all", "none")))

  # make sure parameters are not overwritten even when including all
  parsers_plain <- make_parser(list(all = list(), json = list(simplifyVector = FALSE)))
  expect_equal(
    parsers_plain$alias$json(jsonlite::toJSON(1:3) %>% charToRaw()),
    list(1,2,3)
  )

  parsers_guess <- make_parser(list(all = list(), json = list(simplifyVector = TRUE)))
  expect_equal(
    parsers_guess$alias$json(jsonlite::toJSON(1:3) %>% charToRaw()),
    c(1,2,3)
  )

  # check that parsers return already combined parsers
  expect_parsers(parsers_plain, setdiff(registered_parsers(), c("all", "none")))
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

  expect_equal(r$routes$none$parsers, make_parser("none"))
  expect_equal(r$routes$all$parsers, make_parser("all"))
  expect_equal(r$routes$default$parsers, NULL)
  expect_equal(r$routes$json$parsers, make_parser("json"))
  expect_equal(r$routes$mixed$parsers, make_parser(c("json", "query")))
  expect_equal(r$routes$repeated$parsers, make_parser("json"))
})
