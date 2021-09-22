context("geojson serializer")

test_that("GeoJSON serializes properly", {
  skip_if_not_installed("geojsonsf")
  skip_if_not_installed("sf")

  # Objects taken from ?st_sf() examples.
  sfc <- sf::st_sfc(sf::st_point(1:2), sf::st_point(3:4))
  sf <- sf::st_sf(a = 3:4, g)

  # Test sfc
  val <- serializer_geojson()(sfc, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/geo+json")
  expect_equal(val$body, geojsonsf::sfc_geojson(sfc))

  # Test sf
  val <- serializer_geojson()(sf, data.frame(), PlumberResponse$new(), stop)
  expect_equal(val$status, 200L)
  expect_equal(val$headers$`Content-Type`, "application/geo+json")
  expect_equal(val$body, geojsonsf::sf_geojson(sf))

})

test_that("Errors call error handler", {
  skip_if_not_installed("geojsonsf")
  skip_if_not_installed("sf")

  errors <- 0
  errHandler <- function(req, res, err){
    errors <<- errors + 1
  }

  expect_equal(errors, 0)
  serializer_geojson()(parse(text="hi"), data.frame(), PlumberResponse$new("csv"), errorHandler = errHandler)
  expect_equal(errors, 1)
})
