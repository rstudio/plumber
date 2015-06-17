test_that("paths are properly converted", {
  varRegex <- "([^\\./]+)"
  p <- createPathRegex("/car/:id")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("/car/", varRegex))

  p <- createPathRegex("/car/:id/sell")
  expect_equal(p$names, "id")
  expect_equal(p$regex, paste0("/car/", varRegex, "/sell"))

  p <- createPathRegex("/car/:id/sell/:price")
  expect_equal(p$names, c("id", "price"))
  expect_equal(p$regex, paste0("/car/", varRegex, "/sell/", varRegex))
})

test_that("path regex's are created properly", {
  expect_equal(extractParams(createPathRegex("/car/:id/sell"), "/car/12/sell"), structure("12", names="id") )
  expect_equal(extractParams(createPathRegex("/car/:id"), "/car/15"), structure("15", names="id") )
  expect_equal(extractParams(createPathRegex("/car/:id/sell/:price"), "/car/15/sell/$15,000"), structure(c("15", "$15,000"), names=c("id", "price")) )
})

