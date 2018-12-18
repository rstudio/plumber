

swagger_ui_version <- "3.20.2"
to_location <- file.path("inst", "swagger_ui")

tmp_location <- tempdir()

withr::with_dir(devtools::as.package(".")$path, {
  unlink(to_location, recursive = TRUE)
  dir.create(to_location, recursive = TRUE)
  system(paste0("wget -r -p -np -l 15 -nH -P ", tmp_location, " https://unpkg.com/swagger-ui-dist@", swagger_ui_version, "/"))

  file.path(tmp_location, paste0("swagger-ui-dist@", swagger_ui_version), "") %>%
    dir(full.names = TRUE) %>%
    lapply(file.copy, to = to_location)
})

unlink(tmp_location)

# make sure the petstore swagger call is replaced with local swagger.json call
indexFile <- file.path(to_location, "index.html")
indexFile %>%
  readLines() %>%
  sub(
    "https://petstore.swagger.io/v2/swagger.json",
    'window.location.origin + window.location.pathname.replace(/__swagger__\/$/, "") + "swagger.json"',
    .,
    fixed = TRUE
  ) %>%
  writeLines(indexFile)
