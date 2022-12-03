context("Paths")

test_that("paths are properly converted", {
  varRegex <- "([^/]+)"
  p <- createPathRegex("/car/")
  expect_equal(p$names, character())
  expect_equal(p$regex, "^/car/$")

  p <- createPathRegex("/car/<id>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", varRegex, "$"))

  p <- createPathRegex("/car/<id>/sell")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", varRegex, "/sell$"))

  p <- createPathRegex("/car/<id>/sell/<price>")
  expect_equal(p$names, c("id", "price"))
  expect_equal(p$regex, paste0("^/car/", varRegex, "/sell/", varRegex, "$"))
})

test_that("variables are typed", {
  p <- createPathRegex("/car/<id:int>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "(-?\\d+)", "$"))

  p <- createPathRegex("/car/<id:[int]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:-?\\d+),?)+)", "$"))

  p <- createPathRegex("/car/<id:double>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "(-?\\d*\\.?\\d+)", "$"))
  p <- createPathRegex("/car/<id:[double]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:-?\\d*\\.?\\d+),?)+)", "$"))

  p <- createPathRegex("/car/<id:numeric>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "(-?\\d*\\.?\\d+)", "$"))
  p <- createPathRegex("/car/<id:[numeric]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:-?\\d*\\.?\\d+),?)+)", "$"))

  p <- createPathRegex("/car/<id:bool>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "([01tfTF]|true|false|TRUE|FALSE)", "$"))
  p <- createPathRegex("/car/<id:[bool]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:[01tfTF]|true|false|TRUE|FALSE),?)+)", "$"))

  p <- createPathRegex("/car/<id:logical>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "([01tfTF]|true|false|TRUE|FALSE)", "$"))
  p <- createPathRegex("/car/<id:[logical]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:[01tfTF]|true|false|TRUE|FALSE),?)+)", "$"))

  p <- createPathRegex("/price/<when:date>")
  expect_equal(p$names, "when")
  expect_equal(p$regex, paste0("^/price/", "(\\d{4}-\\d{2}-\\d{2})", "$"))

  p <- createPathRegex("/price/<before:datetime>")
  expect_equal(p$names, "before")
  expect_equal(p$regex, paste0("^/price/", "(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}Z)", "$"))

  p <- createPathRegex("/car/<id:chr>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "([^/]+)", "$"))
  p <- createPathRegex("/car/<id:[chr]>")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", "((?:(?:[^/]+),?)+)", "$"))
  expect_equal(p$areArrays, TRUE)
  expect_equal(p$parsers[[1]]("BOB,LUKE,GUY"), c("BOB", "LUKE", "GUY"))

  #Check that warnings happen on typo or unsupported type
  expect_warning(createPathRegex("/car/<id:motor>"),
                 "Unrecognized type")
  expect_warning(createPathRegex("/car/<id:[motor>"),
                 "Unrecognized type")
  expect_warning(createPathRegex("/car/<id:[df*>"),
                 "Unrecognized type")
  expect_warning(createPathRegex("/car/<id:df]*>"),
                 "Unrecognized type")
  expect_warning(createPathRegex("/car/<id:df]>"),
                 "Unrecognized type")

})

test_that("path regex's are created properly", {
  expect_equivalent(extractPathParams(createPathRegex("/car/"), "/car/"),  list())
  expect_equal(extractPathParams(createPathRegex("/car/<id>"), "/car/15"), list(id="15") )
  expect_equal(extractPathParams(createPathRegex("/car/<id>/sell"), "/car/12/sell"), list(id="12") )
  expect_equal(extractPathParams(createPathRegex("/car/<id>/sell/<price>"), "/car/15/sell/$15,000"), list(id="15", price="$15,000"))
})

test_that("integration of path parsing works", {
  r <- pr(test_path("files/path-params.R"))

  expect_equal(r$route(make_req("GET", "/car/13"), PlumberResponse$new()), "13")
  expect_equal(r$route(make_req("GET", "/car/int/13"), PlumberResponse$new()), 13)
  expect_equal(r$route(make_req("GET", "/car/int/-13"), PlumberResponse$new()), -13)
  expect_equal(r$route(make_req("GET", "/car/15/sell/$15,000"), PlumberResponse$new()), list(id="15", price="$15,000"))
  expect_equal(r$route(make_req("POST", "/car/13"), PlumberResponse$new()), "13")
  expect_equal(r$route(make_req("GET", "/car/15/buy/$15,000"), PlumberResponse$new()),
               list(id=15, price="$15,000"))
  expect_equal(r$route(make_req("GET", "/car/15/buy/$15,000.99"), PlumberResponse$new()),
               list(id=15, price="$15,000.99"))
  expect_equal(r$route(make_req("GET", "/car/ratio/1.5"), PlumberResponse$new()), 1.5)
  expect_equal(r$route(make_req("GET", "/car/ratio/-1.5"), PlumberResponse$new()), -1.5)
  expect_equal(r$route(make_req("GET", "/car/ratio/-.5"), PlumberResponse$new()), -.5)
  expect_equal(r$route(make_req("GET", "/car/ratio/.5"), PlumberResponse$new()), .5)

  expect_equal(r$route(make_req("GET", "/yearend/2022-12-31"), PlumberResponse$new()), lubridate::as_date("2022-12-31"))
  expect_equal(r$route(make_req("GET", "/closing/2022-12-24T18:30:00Z"), PlumberResponse$new()), lubridate::as_datetime("2022-12-24T18:30:00Z"))

  expect_equal(r$route(make_req("GET", "/car/ratio/a"), PlumberResponse$new()),
               list(error = "404 - Resource Not Found"))
  expect_equal(r$route(make_req("GET", "/car/ratio/"), PlumberResponse$new()),
               list(error = "404 - Resource Not Found"))
  expect_equal(r$route(make_req("GET", "/car/ratio/."), PlumberResponse$new()),
               list(error = "404 - Resource Not Found"))
  expect_equal(r$route(make_req("GET", "/car/sold/true"), PlumberResponse$new()), TRUE)
  expect_match(r$call(make_req("POST", "/car/sold/true"))$body,
               "405 - Method Not Allowed")
})

test_that("multiple variations in path works nicely with function args detection", {

  # Check when detection is not provided
  pathDef <- "/<var0:str>/<var1:chr*>/<var2:[int]>/<var3>/<var4:*>/<var5:[*>/<var6:[]*>/<var7:[]>/<var8*>"
  expect_warning(regex <- createPathRegex(pathDef), "Unrecognized type")
  expect_equal(regex$types, c("string", "string", "integer", "string", "string", "string", "string", "string"))
  expect_equal(regex$areArrays, c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE))

  # Check when no args in endpoint function
  dummy <- function() {}
  funcParams <- getArgsMetadata(dummy)
  expect_warning(regex <- createPathRegex(pathDef, funcParams), "Unrecognized type")
  expect_equal(regex$types, c("string", "string", "integer", "string", "string", "string", "string", "string"))
  expect_equal(regex$areArrays, c(FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE))

  # Mix and match
  dummy <- function(var0 = 420.69,
                    var1,
                    var2 = c(1L, 2L),
                    var3 = rnorm,
                    var4 = NULL,
                    var5 = c(TRUE, FALSE),
                    var6 = list(name = c("luke", "bob"), lastname = c("skywalker", "ross")),
                    var7 = new.env(parent = .GlobalEnv),
                    var8 = list(a = 2, b = mean, c = new.env(parent = .GlobalEnv))) {}
  funcParams <- getArgsMetadata(dummy)
  expect_warning(regex <- createPathRegex(pathDef, funcParams), "Unsupported path parameter type")
  expect_equal(regex$types, c("string", "string", "integer", "string", "string", "boolean", "string", "string"))
  expect_equal(regex$areArrays, c(FALSE, FALSE, TRUE, FALSE, FALSE, TRUE, TRUE, TRUE))

  # Throw sand at it
  pathDef <- "/<>/<:chr*>/<:chr>/<henry:[IV]>"
  regex <- createPathRegex(pathDef, funcParams)
  expect_equivalent(regex$types, "string")
  expect_equal(regex$names, "henry")
  # Since type IV is converted to string, areArrays can be TRUE
  expect_equal(regex$areArrays, TRUE)

})
