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
  lines <- c(
    "#' @get /",
    "#' @response 201 This is response 201",
    "#' @response 202 Here's second",
    "#' @response 203 Here's third",
    "#' @response default And default")
  b <- parseBlock(length(lines), lines)
  expect_length(b$responses, 4)
  expect_equal(b$responses$`201`, list(description="This is response 201"))
  expect_equal(b$responses$`202`, list(description="Here's second"))
  expect_equal(b$responses$`203`, list(description="Here's third"))
  expect_equal(b$responses$default, list(description="And default"))

  b <- parseBlock(1, "")
  expect_null(b$responses)
})

test_that("params are parsed", {
  lines <- c(
    "#' @get /",
    "#' @param test Test docs",
    "#' @param required:character* Required param",
    "#' @param another:int Another docs")
  b <- parseBlock(length(lines), lines)
  expect_length(b$params, 3)
  expect_equal(b$params$another, list(desc="Another docs", type="integer", required=FALSE))
  expect_equal(b$params$test, list(desc="Test docs", type=NA, required=FALSE))
  expect_equal(b$params$required, list(desc="Required param", type="string", required=TRUE))

  b <- parseBlock(1, "")
  expect_null(b$params)
})

# TODO
#test_that("prepareSwaggerEndpoints works", {
#})

test_that("swaggerFile works with mounted routers", {
  # parameter in path
  pr <- plumber$new()
  pr$handle("GET", "/nested/:path/here", function(){})
  pr$handle("POST", "/nested/:path/here", function(){})

    # static file handler
  stat <- PlumberStatic$new(".")

  # multiple entries
  pr2 <- plumber$new()
  pr2$handle("GET", "/something", function(){})
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})

  # test with a filter
  pr3 <- plumber$new()
  pr3$filter("filter1", function(){})
  pr3$handle("POST", "/else", function(){}, "filter1")
  pr3$handle("PUT", "/else", function(){})
  pr3$handle("GET", "/", function(){})

  # nested mount
  pr4 <- plumber$new()
  pr4$handle("GET", "/completely", function(){})

  # trailing slash in route
  pr5 <- plumber$new()
  pr5$handle("GET", "/trailing_slash/", function(){})

  # ├──/nested
  # │  ├──/:path
  # │  │  └──/here (GET, POST)
  # ├──/static
  # ├──/sub2
  # │  ├──/something (GET, POST)
  # │  ├──/ (GET)
  # │  ├──/sub3
  # │  │  ├──/else (POST, PUT)
  # │  │  └──/ (GET)
  # ├──/sub4
  # │  ├──/completely (GET)
  # │  ├──/
  # │  │  └──/trailing_slash (GET)
  pr$mount("/static", stat)
  pr2$mount("/sub3", pr3)
  pr$mount("/sub2", pr2)
  pr$mount("/sub4", pr4)
  pr4$mount("/", pr5)

  paths <- names(pr$swaggerFile()$paths)
  expect_length(paths, 7)
  expect_equal(paths, c("/nested/:path/here", "/sub2/something",
    "/sub2/", "/sub2/sub3/else", "/sub2/sub3/", "/sub4/completely",
    "/sub4/trailing_slash/"
  ))

  pr <<- pr
})

test_that("extractResponses works", {
  # Empty
  r <- extractResponses(NULL)
  expect_equal(r, defaultResp)

  # Response constructor actually defaults to NA, so that's an important case, too
  r <- extractResponses(NA)
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
             id2=list(desc="Description2", required=FALSE), # No redundant type specification
             make=list(desc="Make description", type="string", required=FALSE))
  pp <- data.frame(name=c("id", "id2"), type=c("int", "int"))

  params <- extractSwaggerParams(ep, pp)
  expect_equal(params[[1]],
               list(name="id",
                    description="Description",
                    `in`="path",
                    required=TRUE, # Made required b/c path arg
                    schema = list(
                      type="integer")))
  expect_equal(params[[2]],
               list(name="id2",
                    description="Description2",
                    `in`="path",
                    required=TRUE, # Made required b/c path arg
                    schema = list(
                      type="integer")))
  expect_equal(params[[3]],
               list(name="make",
                    description="Make description",
                    `in`="query",
                    required=FALSE,
                    schema = list(
                      type="string")))

  # If id were not a path param it should not be promoted to required
  params <- extractSwaggerParams(ep, NULL)
  idParam <- params[[which(vapply(params, `[[`, character(1), "name") == "id")]]
  expect_equal(idParam$required, FALSE)
  expect_equal(idParam$schema$type, "integer")

  for (param in params) {
    expect_equal(length(param), 5)
  }

  params <- extractSwaggerParams(NULL, NULL)
  expect_equal(length(params), 0)
})
