context("Serializer")

test_that("Responses returned directly aren't serialized", {
  res <- PlumberResponse$new("")

  r <- pr(test_path("files/router.R"))
  val <- r$serve(make_req("GET", "/response123"), res)
  expect_equal(val$body, NULL)
  expect_equal(val$status, 123)
  val <- r$serve(make_req("GET", "/response200"), res)
  expect_equal(val$body, "overridden")
  expect_equal(val$status, 200)
})

test_that("JSON is the default serializer", {
  res <- PlumberResponse$new()

  r <- pr(test_path("files/router.R"))
  expect_equal(r$serve(make_req("GET", "/"), res)$headers$`Content-Type`, "application/json")
})

test_that("Overridden serializers apply on filters and endpoints", {

  with_tmp_serializers({
    customSer <- function(){
      function(val, req, res, errorHandler){
        list(status=201L, headers=list(), body="CUSTOM")
      }
    }
    register_serializer("custom", customSer)

    custom2Ser <- function(){
      function(val, req, res, errorHandler){
        list(status=201L, headers=list(), body="CUSTOM2")
      }
    }
    register_serializer("custom2", custom2Ser)

    register_serializer("customOneArg", function(single){
      function(val, req, res, errorHandler){
        list(status=200L, headers=list(), body=list(val=val, arg=single))
      }
    })

    register_serializer("customMultiArg", function(first, second, third){
      function(val, req, res, errorHandler){
        list(status=200L, headers=list(),
            body=list(val=val, args=list(first=first, second=second, third=third)))
      }
    })

    r <- pr(test_path("files/serializer.R"))
    res <- PlumberResponse$new("json")
    expect_equal(r$serve(make_req("GET", "/"), res)$body, "CUSTOM")
    expect_equal(res$serializer, customSer())

    res <- PlumberResponse$new("json")
    expect_equal(r$serve(make_req("GET", "/filter-catch"), res)$body, "CUSTOM2")
    expect_equal(res$serializer, custom2Ser())

    req <- make_req("GET", "/something")
    res <- PlumberResponse$new(customSer())
    expect_equal(r$serve(req, res)$body, "CUSTOM")

    # have the filter set the serializer
    req <- make_req("GET", "/something", qs = "type=json")
    res <- PlumberResponse$new(NULL) # default to something that doesn't exist!
    expect_equal(r$serve(req, res)$body, jsonlite::toJSON(4))

    res <- PlumberResponse$new("json")
    expect_equal(r$serve(make_req("GET", "/another"), res)$body, "CUSTOM3")

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

  # due to covr changing some code, the return answer is very strange
  # the tests below should be skipped on covr
  testthat::skip_on_covr()

  res <- PlumberResponse$new()
  expect_equal(r$serve(make_req("GET", "/short-json"), res)$body, jsonlite::toJSON("JSON"))
  expect_equal_functions(res$serializer, serializer_json())

  res <- PlumberResponse$new()
  expect_equal(r$serve(make_req("GET", "/short-html"), res)$body, "HTML")
  expect_equal_functions(res$serializer, serializer_html())
})

# test_that("Overridding the attached serializer in code works.", {
#
# })

test_that("Redundant serializers fail", {

  with_tmp_serializers({
    register_serializer("inc", function(val, req, res, errorHandler){
      list(status=201L, headers=list(), body="CUSTOM2")
    })
    expect_error(pr(test_path("files/serializer-redundant.R")), regexp="Multiple @serializers")
  })

})

test_that("Empty serializers fail", {
  expect_error(pr(test_path("files/serializer-empty.R")), regexp="No @serializer specified")
})

test_that("Non-existant serializers fail", {
  expect_error(pr(test_path("files/serializer-nonexistent.R")), regexp="No such @serializer")
})


test_that("serializer_identity serializes properly", {
  v <- "<html><h1>Hi!</h1></html>"
  val <- serializer_identity()(v, list(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$body, v)
})

test_that("serializer_identity errors call error handler", {
  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_identity()(parse(stop("I crash")), list(), PlumberResponse$new("json"), errorHandler = errHandler)
  expect_equal(errors, 1)
})

test_that("Error handler is passed to serializer", {

  with_tmp_serializers({
    res <- PlumberResponse$new()

    register_serializer("failingSer", function() {
      function(val, req, res, errorHandler){
        errorHandler(req, res, simpleError("A serializer error"))
      }
    })

    r <- pr(test_path("files/serializer-error.R"))

    r$setErrorHandler(function(req, res, err) {
      msg <- paste("Handled:", conditionMessage(err))
      stop(msg)
    })

    expect_error(r$serve(make_req("GET", "/fail"), res),
                regexp = "Handled: A serializer error")
  })
})
