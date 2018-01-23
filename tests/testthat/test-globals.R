context("global settings")

test_that("parseOneGlobal parses with various formats", {
  fields <- list(info=list())

  # No leading space
  g <- parseOneGlobal(fields, "#'@apiTitle Title")
  expect_equal(g$info$title, "Title")

  # Plumber-style
  g <- parseOneGlobal(fields, "#* @apiTitle Title")
  expect_equal(g$info$title, "Title")

  #Extra space
  g <- parseOneGlobal(fields, "#*    @apiTitle     Title   ")
  expect_equal(g$info$title, "Title")
})

test_that("parseGlobals works", {
  # Test all fields
  lines <- c("#' @apiTitle title",
             "#' @apiDescription description",
             "#' @apiTOS tos",
             "#' @apiContact contact",
             "#' @apiLicense license",
             "#' @apiVersion version",
             "#' @apiHost host",
             "#' @apiBasePath basepath",
             "#' @apiSchemes schemes",
             "#' @apiConsumes consumes",
             "#' @apiProduces produces",
             "#' @apiTag tag description",
             "#' @apiTag tag2 description2")

  fields <- parseGlobals(lines)

  expect_equal(fields, list(
    info=list(
      title="title",
      description="description",
      termsOfService="tos",
      contact="contact",
      license="license",
      version="version"
    ),
    host="host",
    basePath="basepath",
    schemes="schemes",
    consumes="consumes",
    produces="produces",
    tags=data.frame(name=c("tag","tag2"),description=c("description","description2"), stringsAsFactors = FALSE)
  ))
})

test_that("Globals can't contain duplicate tags", {
  lines <- c("#* @apiTag test description1",
             "#* @apiTag test description2")
  expect_error(parseGlobals(lines), "Duplicate tag definition specified.")
})
