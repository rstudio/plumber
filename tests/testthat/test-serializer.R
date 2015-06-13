make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("JSON is the default serializer", {
  res <- RapierResponse$new("json")

  r <- RapierRouter$new("files/router.R")
  expect_equal(r$serve(make_req("GET", "/"), res)$headers$`Content-Type`, "application/json")
})

test_that("Overridden serializers apply on filters and endpoints", {

  addSerializer("custom", function(val, req, res, errorHandler){
    list(status=201L, headers=list(), body="CUSTOM")
  })
  addSerializer("custom2", function(val, req, res, errorHandler){
    list(status=201L, headers=list(), body="CUSTOM2")
  })

  r <- RapierRouter$new("files/serializer.R")
  res <- RapierResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/"), res)$body, "CUSTOM")
  expect_equal(res$serializer, "custom")

  res <- RapierResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/filter-catch"), res)$body, "CUSTOM2")
  expect_equal(res$serializer, "custom2")

  req <- make_req("GET", "/something")
  res <- RapierResponse$new("custom")
  expect_equal(r$serve(req, res)$body, "CUSTOM")
  res$serializer <- "custom"

  req$QUERY_STRING <- "type=json"
  expect_equal(r$serve(req, res)$body, jsonlite::toJSON(4))
  res$serializer <- "json"

  res <- RapierResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/another"), res)$body, "CUSTOM2")
  expect_equal(res$serializer, "custom2")
})

test_that("Overridding the attached serializer in code works.", {

})

test_that("Redundant serializers fail", {
  addSerializer("inc", function(val, req, res, errorHandler){
    list(status=201L, headers=list(), body="CUSTOM2")
  })
  expect_error(RapierRouter$new("files/serializer-redundant.R"), regexp="Multiple @serializers")
})

test_that("Empty serializers fail", {
  expect_error(RapierRouter$new("files/serializer-empty.R"), regexp="No @serializer specified")
})

test_that("Non-existant serializers fail", {
  expect_error(RapierRouter$new("files/serializer-nonexistent.R"), regexp="No such @serializer")
})
