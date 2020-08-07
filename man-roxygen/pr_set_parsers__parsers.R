#' @param parsers
#'
#'   Can be one of:
#'   * A `NULL` value
#'   * A character vector of parser names
#'   * A named `list()` whose keys are parser names names and values are arguments to be applied with [do.call()]
#'   * A `TRUE` value, which will default to combining all parsers. This is great for seeing what is possible, but not great for security purposes
#'
#'   If the parser name `"all"` is found in any character value or list name, all remaining parsers will be added.
#'   When using a list, parser information already defined will maintain their existing argument values.  All remaining parsers will use their default arguments.
#'
#' Example:
#' ```
#' # provide a character string
#' parsers = "json"
#'
#' # provide a named list with no arguments
#' parsers = list(json = list())
#'
#' # provide a named list with arguments; include `rds`
#' parsers = list(json = list(simplifyVector = FALSE), rds = list())
#'
#' # default plumber parsers
#' parsers = c("json", "form", "text", "octet", "multi")
#' ```
