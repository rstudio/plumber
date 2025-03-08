#' Validate OpenAPI Spec
#'
#' Validate an OpenAPI Spec using [`@redocly/cli`](https://redocly.com/docs/cli/commands/lint).
#'
#' If any warning or error is presented, an error will be thrown.
#'
#' This function is `r lifecycle::badge("experimental")` and may be altered, changed, or removed in the future.
#'
#' @param pr A Plumber API
#' @param ... Ignored
#' @param ruleset Character that determines the ruleset to use for validation. Can be one of "minimal", "recommended",
#' or "recommended-strict". Defaults to "minimal". See [`@redocly/cli`
#' options](https://redocly.com/docs/cli/commands/lint#options) for more details.
#' @param verbose Logical that determines if a "is valid" statement is displayed. Defaults to `TRUE`
#' @export
#' @examples
#' \dontrun{
#' pr <- plumb_api("plumber", "01-append")
#' validate_api_spec(pr)
#' }
validate_api_spec <- function(pr, ..., ruleset = c("minimal", "recommended", "recommended-strict"), verbose = TRUE) {

  ruleset <- match.arg(ruleset, several.ok = FALSE)
  if (!nzchar(Sys.which("node"))) {
    stop("`node` command not found. Please install Node.js")
  }
  if (!nzchar(Sys.which("npx"))) {
    stop("`npx` not installed. Please install Node.js w/ `npx` command available.")
  }
  
  spec <- jsonlite::toJSON(pr$getApiSpec(), auto_unbox = TRUE, pretty = TRUE)

  tmpfile <- tempfile(fileext = ".json")
  on.exit({
    unlink(tmpfile)
  }, add = TRUE)
  cat(spec, file = tmpfile)

  output <- system2(
    "npx",
    c(
      "--yes", # auto install `@redocly/cli`
      "-p", "@redocly/cli",
      "redocly",
      "lint",
      "--extends", ruleset,
      "--skip-rule", "no-empty-servers", # We don't know the end servers by default
      "--skip-rule", "security-defined", # We don't know the security by default
      "--skip-rule", "operation-summary", # operation summary values are optional. Not required
      "--skip-rule", "operation-operationId-url-safe", # By default, it wants to have all operationId values be URL safe. This does not work with path parameters that want to use `{``}`.
      "--skip-rule", "no-path-trailing-slash", # This is OK
      tmpfile
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  
  output <- paste0(output, collapse = "\n")

  has_warn_or_error <- grepl("\n[1] ", output, fixed = TRUE)
  if (has_warn_or_error) {
    cat("Plumber Spec: \n", as.character(spec), "\n\nOutput:\n", output, sep = "")
    stop("Plumber OpenAPI Spec is not valid")
  }

  invisible(TRUE)
}
