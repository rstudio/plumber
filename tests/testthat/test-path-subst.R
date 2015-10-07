make_req <- function(verb, path){
  req <- new.env()
  req$REQUEST_METHOD <- toupper(verb)
  req$PATH_INFO <- path
  req$rook.input <- list(read_lines = function(){ "" })
  req
}

test_that("paths are properly converted", {
  varRegex <- "([^\\./]+)"
  p <- createPathRegex("/car/")
  expect_equal(p$names, character())
  expect_equal(p$regex, "^/car/$")

  p <- createPathRegex("/car/:id")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", varRegex, "$"))

  p <- createPathRegex("/car/:id/sell")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("^/car/", varRegex, "/sell$"))

  p <- createPathRegex("/car/:id/sell/:price")
  expect_equal(p$names, c("id", "price"))
  expect_equal(p$regex, paste0("^/car/", varRegex, "/sell/", varRegex, "$"))
})

test_that("path regex's are created properly", {
  expect_equivalent(extractPathParams(createPathRegex("/car/"), "/car/"),  character())
  expect_equal(extractPathParams(createPathRegex("/car/:id"), "/car/15"), structure("15", names="id") )
  expect_equal(extractPathParams(createPathRegex("/car/:id/sell"), "/car/12/sell"), structure("12", names="id") )
  expect_equal(extractPathParams(createPathRegex("/car/:id/sell/:price"), "/car/15/sell/$15,000"), structure(c("15", "$15,000"), names=c("id", "price")) )
})

test_that("integration of path parsing works", {
  r <- plumber$new("files/path-params.R")
  expect_equal(r$route(make_req("GET", "/car/13"), PlumberResponse$new()), "13")
  expect_equal(r$route(make_req("GET", "/car/15/sell/$15,000"), PlumberResponse$new()), list(id="15", price="$15,000"))
  expect_equal(r$route(make_req("POST", "/car/13"), PlumberResponse$new()), "13")
})
