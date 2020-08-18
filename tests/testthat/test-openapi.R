context("OpenAPI")

test_that("plumberToApiType works", {
  expect_equal(plumberToApiType("bool"), "boolean")
  expect_equal(plumberToApiType("logical"), "boolean")

  expect_equal(plumberToApiType("double"), "number")
  expect_equal(plumberToApiType("numeric"), "number")

  expect_equal(plumberToApiType("int"), "integer")

  expect_equal(plumberToApiType("character"), "string")

  expect_equal(plumberToApiType("df"), "object")
  expect_equal(plumberToApiType("list"), "object")
  expect_equal(plumberToApiType("data.frame"), "object")

  expect_warning({
    expect_equal(plumberToApiType("flargdarg"),  defaultApiType)
  }, "Unrecognized type:")
})

test_that("response attributes are parsed", {
  lines <- c(
    "#' @get /",
    "#' @response 201 This is response 201",
    "#' @response 202 Here's second",
    "#' @response 203 Here's third",
    "#' @response default And default")
  b <- plumbBlock(length(lines), lines)
  expect_length(b$responses, 4)
  expect_equal(b$responses$`201`, list(description="This is response 201"))
  expect_equal(b$responses$`202`, list(description="Here's second"))
  expect_equal(b$responses$`203`, list(description="Here's third"))
  expect_equal(b$responses$default, list(description="And default"))

  b <- plumbBlock(1, "")
  expect_null(b$responses)
})

test_that("params are parsed", {
  lines <- c(
    "#' @get /",
    "#' @param test Test docs",
    "#' @param required:character* Required param",
    "#' @param another:int Another docs",
    "#' @param multi:[int]* Required array param")
  b <- plumbBlock(length(lines), lines)
  expect_length(b$params, 4)
  expect_equal(b$params$another, list(desc="Another docs", type="integer", required=FALSE, isArray = FALSE))
  expect_equal(b$params$test, list(desc="Test docs", type=defaultApiType, required=FALSE, isArray = FALSE))
  expect_equal(b$params$required, list(desc="Required param", type="string", required=TRUE, isArray = FALSE))
  expect_equal(b$params$multi, list(desc="Required array param", type="integer", required=TRUE, isArray = TRUE))

  b <- plumbBlock(1, "")
  expect_null(b$params)
})

# TODO
#test_that("endpointSpecification works", {
#})

test_that("getApiSpec works with mounted routers", {
  # parameter in path
  pr1 <- pr()
  pr1$handle("GET", "/nested/:path/here", function(){})
  pr1$handle("POST", "/nested/:path/here", function(){})

    # static file handler
  stat <- PlumberStatic$new(".")

  # multiple entries
  pr2 <- pr()
  pr2$handle("GET", "/something", function(){})
  pr2$handle("POST", "/something", function(){})
  pr2$handle("GET", "/", function(){})

  # test with a filter
  pr3 <- pr()
  pr3$filter("filter1", function(){})
  pr3$handle("POST", "/else", function(){}, "filter1")
  pr3$handle("PUT", "/else", function(){})
  pr3$handle("GET", "/", function(){})

  # nested mount
  pr4 <- pr()
  pr4$handle("GET", "/completely", function(){})

  # trailing slash in route
  pr5 <- pr()
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
  pr1$mount("/static", stat)
  pr2$mount("/sub3", pr3)
  pr1$mount("/sub2", pr2)
  pr1$mount("/sub4", pr4)
  pr4$mount("/", pr5)

  paths <- names(pr1$getApiSpec()$paths)
  expect_length(paths, 7)
  expect_equal(paths, c("/nested/:path/here", "/sub2/something",
    "/sub2/", "/sub2/sub3/else", "/sub2/sub3/", "/sub4/completely",
    "/sub4/trailing_slash/"
  ))
})

test_that("responsesSpecification works", {
  # Empty
  r <- responsesSpecification(NULL)
  expect_equal(r, defaultResponse)

  # Response constructor actually defaults to NA, so that's an important case, too
  r <- responsesSpecification(NA)
  expect_equal(r, defaultResponse)

  # Responses with no default
  customResps <- list("200" = list())
  r <- responsesSpecification(customResps)
  expect_length(r, 2)
  expect_equal(r$default, defaultResponse$default)
  expect_equal(r$`200`, customResps$`200`)
})

test_that("parametersSpecification works", {
  ep <- list(id=list(desc="Description", type="integer", required=FALSE),
             id2=list(desc="Description2", required=FALSE), # No redundant type specification
             make=list(desc="Make description", type="string", required=FALSE),
             prices=list(desc="Historic sell prices", type="numeric", required = FALSE, isArray = TRUE),
             claims=list(desc="Insurance claims", type="object", required = FALSE))
  pp <- data.frame(name=c("id", "id2", "owners"), type=c("int", "int", "chr"), isArray = c(FALSE, FALSE, TRUE), stringsAsFactors = FALSE)

  params <- parametersSpecification(ep, pp)
  expect_equal(params$parameters[[1]],
               list(name="id",
                    description="Description",
                    `in`="path",
                    required=TRUE, # Made required b/c path arg
                    schema = list(
                      type="integer",
                      format="int64",
                      default=NULL)))
  expect_equal(params$parameters[[2]],
               list(name="id2",
                    description="Description2",
                    `in`="path",
                    required=TRUE, # Made required b/c path arg
                    schema = list(
                      type="integer",
                      format="int64",
                      default=NULL)))
  expect_equal(params$parameters[[3]],
               list(name="make",
                    description="Make description",
                    `in`="query",
                    required=FALSE,
                    schema = list(
                      type="string",
                      format=NULL,
                      default=NULL)))
  expect_equal(params$parameters[[4]],
               list(name="prices",
                    description="Historic sell prices",
                    `in`="query",
                    required=FALSE,
                    schema = list(
                      type="array",
                      items= list(
                        type="number",
                        format="double"),
                      default = NULL),
                    style="form",
                    explode=TRUE))
  expect_equal(params$parameters[[5]],
               list(name="owners",
                    description=NULL,
                    `in`="path",
                    required=TRUE,
                    schema = list(
                      type="array",
                      items= list(
                        type="string",
                        format=NULL),
                      default = NULL),
                    style="simple",
                    explode=FALSE))
  expect_equal(params$requestBody,
               list(content = list(
                 `application/json` = list(
                   schema = list(
                     type = "object",
                     properties = list(
                       claims = list(
                         type = "object",
                         format = NULL,
                         example = NULL,
                         description = "Insurance claims")))))))

  # If id were not a path param it should not be promoted to required
  params <- parametersSpecification(ep, NULL)
  idParam <- params$parameters[[which(vapply(params$parameters, `[[`, character(1), "name") == "id")]]
  expect_equal(idParam$required, FALSE)
  expect_equal(idParam$schema$type, "integer")

  for (param in params$parameters) {
    if (param$schema$type != "array") {
      expect_equal(length(param), 5)
    } else {
      expect_equal(length(param), 7)
    }
  }

  # Check if we can pass a single path parameter without a @param line match
  params <- parametersSpecification(NULL, pp[3,])
  expect_equal(params$parameters[[1]],
               list(name="owners",
                    description=NULL,
                    `in`="path",
                    required=TRUE,
                    schema = list(
                      type="array",
                      items= list(
                        type="string",
                        format=NULL),
                      default=NULL),
                    style="simple",
                    explode=FALSE))

  params <- parametersSpecification(NULL, NULL)
  expect_equal(sum(sapply(params, length)), 0)
})

test_that("api kitchen sink", {

  skip_on_cran()
  skip_on_bioc()
  skip_on_os(setdiff(c("windows", "mac", "linux", "solaris"), c("mac", "linux")))

  ## install brew - https://brew.sh/
  # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  ## install yarn
  # brew install yarn
  ## install yarn
  # yarn add swagger-ui

  # yarn install

  skip_if_not(nzchar(Sys.which("node")), "node not installed")
  skip_if_not(nzchar(Sys.which("npm")), "`npm` system dep not installed")

  for_each_plumber_api(validate_api_spec, verbose = FALSE)

  # TODO test more situations
})

test_that("multiple variations in function extract correct metadata", {
  dummy <- function(var0 = 420.69,
                    var1,
                    var2 = c(1L, 2L),
                    var3 = rnorm,
                    var4 = NULL,
                    var5 = FALSE,
                    var6 = list(name = c("luke", "bob"), lastname = c("skywalker", "ross")),
                    var7 = .GlobalEnv,
                    var8 = list(a = 2, b = mean, c = .GlobalEnv)) {}
  funcParams <- getArgsMetadata(dummy)
  expect_identical(sapply(funcParams, `[[`, "required"),
                   c(var0 = FALSE, var1 = TRUE, var2 = FALSE, var3 = FALSE, var4 = FALSE,
                     var5 = FALSE, var6 = FALSE, var7 = FALSE, var8 = FALSE))
  expect_identical(lapply(funcParams, `[[`, "default"),
                   list(var0 = 420.69, var1 = NA, var2 = 1L:2L, var3 = NA, var4 = NA, var5 = FALSE,
                        var6 = list(name = c("luke", "bob"), lastname = c("skywalker", "ross")), var7 = NA, var8 = NA))
  expect_identical(lapply(funcParams, `[[`, "example"),
                   list(var0 = 420.69, var1 = NA, var2 = 1L:2L, var3 = NA, var4 = NA, var5 = FALSE,
                        var6 = list(name = c("luke", "bob"), lastname = c("skywalker", "ross")), var7 = NA, var8 = NA))
  expect_identical(lapply(funcParams, `[[`, "isArray"),
                   list(var0 = defaultIsArray, var1 = defaultIsArray, var2 = TRUE,
                        var3 = defaultIsArray, var4 = defaultIsArray,
                        var5 = defaultIsArray, var6 = defaultIsArray,
                        var7 = defaultIsArray, var8 = defaultIsArray))
  expect_identical(lapply(funcParams, `[[`, "type"),
                   list(var0 = "number", var1 = defaultApiType, var2 = "integer", var3 = defaultApiType, var4 = defaultApiType,
                        var5 = "boolean", var6 = "object", var7 = defaultApiType, var8 = defaultApiType))

})

test_that("priorize works as expected", {
  expect_identical("abc", priorizeProperty(structure("zzz", default = TRUE), NULL, "abc"))
  expect_identical(NULL, priorizeProperty(NULL, NULL, NULL))
  expect_identical(structure("zzz", default = TRUE), priorizeProperty(structure("zzz", default = TRUE), NULL, NA))
  expect_identical(NULL, priorizeProperty())
})

test_that("custom spec works", {
  pr <- pr()
  pr$handle("POST", "/func1", function(){})
  pr$handle("GET", "/func2", function(){})
  pr$handle("GET", "/func3", function(){})
  customSpec <- function(spec) {
    custom <- list(info = list(description = "My Custom Spec", title = "This is only a test"))
    return(utils::modifyList(spec, custom))
  }
  pr$setApiSpec(customSpec)
  spec <- pr$getApiSpec()
  expect_equal(spec$info$description, "My Custom Spec")
  expect_equal(spec$info$title, "This is only a test")
  expect_equal(class(spec$openapi), "character")
})

test_that("no params plumber router still produces spec when there is a func params", {
  pr <- pr()
  handler <- function(num) { sum(as.integer(num)) }
  pr$handle("GET", "/sum", handler, serializer = serializer_json())
  spec <- pr$getApiSpec()
  expect_equal(spec$paths$`/sum`$get$parameters[[1]]$name, "num")
})
