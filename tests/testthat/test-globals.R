context("global settings")

test_that("plumbOneGlobal parses with various formats", {
  fields <- list(info=list())

  # No leading space
  g <- plumbOneGlobal(fields, "#'@apiTitle Title")
  expect_equal(g$info$title, "Title")

  # Plumber-style
  g <- plumbOneGlobal(fields, "#* @apiTitle Title")
  expect_equal(g$info$title, "Title")

  #Extra space
  g <- plumbOneGlobal(fields, "#*    @apiTitle     Title   ")
  expect_equal(g$info$title, "Title")
})

test_that("plumbGlobals works", {
  # Test all fields
  lines <- c("#' @apiTitle title",
             "#' @apiDescription description",
             "#' @apiTOS tos",
             "#' @apiContact contact",
             "#' @apiLicense license",
             "#' @apiVersion version",
             "#' @apiTag t d",
             "#' @apiTag tag description",
             "#' @apiTag tag2 description2",
             "#' @apiTag tag3 description in part",
             "#' @apiTag 'tag4 space' spaces",
             "#' @apiTag \"tag5 space\" spaces")

  fields <- plumbGlobals(lines)

  expect_equal(fields, list(
    info=list(
      title="title",
      description="description",
      termsOfService="tos",
      contact="contact",
      license="license",
      version="version"
    ),
    tags=list(list(name="t", description="d"),
              list(name="tag", description="description"),
              list(name="tag2", description="description2"),
              list(name="tag3", description="description in part"),
              list(name="tag4 space", description="spaces"),
              list(name="tag5 space", description="spaces"))
  ))

  # Test contact and licence object
  lines <- c('#* @apiContact list(name = "API Support", url = "http://www.example.com/support", email = "support@example.com")',
             '#* @apiLicense list(name = "Apache 2.0", url = "https://www.apache.org/licenses/LICENSE-2.0.html")')

  fields <- plumbGlobals(lines)

  expect_equal(fields, list(
    info=list(
      contact=list(name = "API Support", url = "http://www.example.com/support", email = "support@example.com"),
      license=list(name = "Apache 2.0", url = "https://www.apache.org/licenses/LICENSE-2.0.html")
    )
  ))
})

test_that("Globals can't contain duplicate tags", {
  lines <- c("#* @apiTag test description1",
             "#* @apiTag test description2")
  expect_error(plumbGlobals(lines), "Duplicate tag definition specified.")
})
