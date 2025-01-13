
#' @include globals.R
validate_api_spec_folder <- function() {
  file.path(tempdir(), "plumber_validate_api_spec")
}


validate_api_spec__install_node_modules <- function() {

  if (!nzchar(Sys.which("node"))) {
    stop("node not installed")
  }
  if (!nzchar(Sys.which("npm"))) {
    stop("npm not installed")
  }

  if (dir.exists(validate_api_spec_folder())) {
    # assume npm install has completed
    return(invisible(TRUE))
  }

  dir.create(validate_api_spec_folder(), recursive = TRUE, showWarnings = FALSE)

  file.copy(
    system.file(file.path("validate_api_spec", "package.json"), package = "plumber"),
    file.path(validate_api_spec_folder(), "package.json")
  )

  old_wd <- setwd(validate_api_spec_folder())
  on.exit({
    setwd(old_wd)
  }, add = TRUE)

  # install everything. Ignore regular output
  status <- system2("npm", c("install", "--loglevel", "warn"), stdout = FALSE)
  if (status != 0) {
      # delete the folder if it didn't work
      unlink(validate_api_spec_folder(), recursive = TRUE)
      stop("Could not install npm dependencies required for plumber::validate_api_spec()")
  }

  invisible(TRUE)
}


#' Validate OpenAPI Spec
#'
#' Validate an OpenAPI Spec using [Swagger CLI](https://github.com/APIDevTools/swagger-cli) which calls [Swagger Parser](https://github.com/APIDevTools/swagger-parser).
#'
#' If the api is deemed invalid, an error will be thrown.
#'
#' This function is VERY `r lifecycle::badge("experimental")` and may be altered, changed, or removed in the future.
#'
#' @param pr A Plumber API
#' @param verbose Logical that determines if a "is valid" statement is displayed. Defaults to `TRUE`
#' @export
#' @examples
#' \dontrun{
#' pr <- plumb_api("plumber", "01-append")
#' validate_api_spec(pr)
#' }
validate_api_spec <- function(pr, verbose = TRUE) {

  validate_api_spec__install_node_modules()

  spec <- jsonlite::toJSON(pr$getApiSpec(), auto_unbox = TRUE, pretty = TRUE)
  old_wd <- setwd(validate_api_spec_folder())
  on.exit({
    setwd(old_wd)
  }, add = TRUE)

  tmpfile <- tempfile(fileext = ".json")
  on.exit({
    unlink(tmpfile)
  }, add = TRUE)
  cat(spec, file = tmpfile)

  output <- system2(
    "node_modules/.bin/swagger-cli",
    c(
      "validate",
      tmpfile
    ),
    stdout = TRUE,
    stderr = TRUE
  )

  output <- paste0(output, collapse = "\n")

  # using expect_equal vs a regex test to have a better error message
  is_equal <- sub(tmpfile, "", output, fixed = TRUE) == " is valid"
  if (!isTRUE(is_equal)) {
    cat("Plumber Spec: \n", as.character(spec), "\nOutput:\n", output)
    stop("Plumber OpenAPI Spec is not valid")
  }

  if (isTRUE(verbose)) {
    cat(crayon::green("\u2714"), crayon::silver(": Plumber OpenAPI Spec is valid"), "\n", sep = "")
  }

  invisible(TRUE)
}
