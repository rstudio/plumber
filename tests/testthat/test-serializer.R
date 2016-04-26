make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("Responses returned directly aren't serialized", {
  res <- PlumberResponse$new("")

  r <- plumber$new("files/router.R")
  val <- r$serve(make_req("GET", "/response"), res)
  expect_equal(val$body, "overridden")
  expect_equal(val$status, 123)
})

test_that("JSON is provided when serializer is NULL", {
  res <- PlumberResponse$new(NULL)

  r <- plumber$new("files/router.R")
  expect_equal(r$serve(make_req("GET", "/"), res)$headers$`Content-Type`, "application/json")
})

test_that("JSON is the default serializer", {
  res <- PlumberResponse$new()

  r <- plumber$new("files/router.R")
  expect_equal(r$serve(make_req("GET", "/"), res)$headers$`Content-Type`, "application/json")
})

test_that("Overridden serializers apply on filters and endpoints", {
  customSer <- function(){
    function(val, req, res, errorHandler){
      list(status=201L, headers=list(), body="CUSTOM")
    }
  }
  addSerializer("custom", customSer)

  custom2Ser <- function(){
    function(val, req, res, errorHandler){
      list(status=201L, headers=list(), body="CUSTOM2")
    }
  }
  addSerializer("custom2", custom2Ser)

  addSerializer("customOneArg", function(single){
    function(val, req, res, errorHandler){
      list(status=200L, headers=list(), body=list(val=val, arg=single))
    }
  })

  addSerializer("customMultiArg", function(first, second, third){
    function(val, req, res, errorHandler){
      list(status=200L, headers=list(),
           body=list(val=val, args=list(first=first, second=second, third=third)))
    }
  })

  r <- plumber$new("files/serializer.R")
  res <- PlumberResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/"), res)$body, "CUSTOM")
  expect_equal(res$serializer, customSer())

  res <- PlumberResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/filter-catch"), res)$body, "CUSTOM2")
  expect_equal(res$serializer, custom2Ser())

  req <- make_req("GET", "/something")
  res <- PlumberResponse$new(customSer())
  expect_equal(r$serve(req, res)$body, "CUSTOM")
  res$serializer <- customSer()

  req <- make_req("GET", "/something")
  req$QUERY_STRING <- "type=json"
  expect_equal(r$serve(req, res)$body, jsonlite::toJSON(4))
  res$serializer <- jsonSerializer()

  res <- PlumberResponse$new("json")
  expect_equal(r$serve(make_req("GET", "/another"), res)$body, "CUSTOM3")

  res <- PlumberResponse$new()
  expect_equal(r$serve(make_req("GET", "/short-json"), res)$body, jsonlite::toJSON("JSON"))
  expect_equal(res$serializer, jsonSerializer())

  res <- PlumberResponse$new()
  expect_equal(r$serve(make_req("GET", "/short-html"), res)$body, "HTML")
  expect_equal(res$serializer, htmlSerializer())

  res <- PlumberResponse$new()
  body <- r$serve(make_req("GET", "/single-arg-ser"), res)$body
  expect_equal(body$val, "COA")
  expect_equal(body$arg, "hi there")

  res <- PlumberResponse$new()
  body <- r$serve(make_req("GET", "/multi-arg-ser"), res)$body
  expect_equal(body$val, "MAS")
  expect_equal(body$args$first, "A")
  expect_equal(body$args$second, 8)
  expect_equal(body$args$third, 4.3)
})

test_that("Overridding the attached serializer in code works.", {

})

test_that("Redundant serializers fail", {
  addSerializer("inc", function(val, req, res, errorHandler){
    list(status=201L, headers=list(), body="CUSTOM2")
  })
  expect_error(plumber$new("files/serializer-redundant.R"), regexp="Multiple @serializers")
})

test_that("Empty serializers fail", {
  expect_error(plumber$new("files/serializer-empty.R"), regexp="No @serializer specified")
})

test_that("Non-existant serializers fail", {
  expect_error(plumber$new("files/serializer-nonexistent.R"), regexp="No such @serializer")
})
