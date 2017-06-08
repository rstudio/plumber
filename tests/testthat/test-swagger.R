context("swagger")

test_that("plumberToSwaggerType works", {
  expect_equal(plumberToSwaggerType("bool"), "boolean")
  expect_equal(plumberToSwaggerType("logical"), "boolean")

  expect_equal(plumberToSwaggerType("double"), "number")
  expect_equal(plumberToSwaggerType("numeric"), "number")

  expect_equal(plumberToSwaggerType("int"), "integer")

  expect_equal(plumberToSwaggerType("character"), "string")

  expect_error(plumberToSwaggerType("flargdarg"), "Unrecognized type:")
})

test_that("response attributes are parsed", {
  testthat::fail()
})

test_that("params are parsed", {
  # Name, type, required, description
  testthat::fail()
})

test_that("prepareSwaggerEndpoints works", {
  testthat::fail()
})

test_that("extractResponses works", {
  # Empty
  r <- extractResponses(NULL)
  expect_equal(r, defaultResp)

  # Responses with no default
  customResps <- list("200" = list())
  r <- extractResponses(customResps)
  expect_length(r, 2)
  expect_equal(r$default, defaultResp$default)
  expect_equal(r$`200`, customResps$`200`)
})

test_that("extractSwaggerParams works", {
  ep <- list(id=list(desc="Description", type="integer", required=FALSE),
             make=list(desc="Make description", type="string", required=FALSE))
  pp <- data.frame(name="id", type="int")

  params <- extractSwaggerParams(ep, pp)
  expect_equal(as.list(params[1,]),
               list(name="id",
                    description="Description",
                    `in`="path",
                    required=TRUE, # Made required b/c path arg
                    type="integer"))
  expect_equal(as.list(params[2,]),
               list(name="make",
                    description="Make description",
                    `in`="query",
                    required=FALSE,
                    type="string"))

  # If id were not a path param it should not be promoted to required
  params <- extractSwaggerParams(ep, NULL)
  expect_equal(params$required[params$name=="id"], FALSE)

  params <- extractSwaggerParams(NULL, NULL)
  expect_equal(nrow(params), 0)
  expect_equal(ncol(params), 5)
})
