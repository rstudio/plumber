

# calculate all OpenAPI Type information at once and use created information throughout package
apiTypesInfo <- list()
defaultApiType <- structure("string", default = TRUE)
defaultIsArray <- structure(FALSE, default = TRUE)

add_api_info_onLoad <- function() {
  addApiInfo <- function(
    keys,
    openApiType = c("string", "number", "integer", "boolean", "object"),
    # note that openApiFormat is extensible - so match.arg should not be used on openApiFormat
    openApiFormat = c("float", "double", "int32", "int64", "date", "date-time", "password", "byte", "binary"),
    openApiRegex  = NULL,
    location = c("requestBody", "path", "query"),
    parser = function(input) { input; }) {

    if (missing(location)) {
      location <- NULL
    } else {
      location <- match.arg(location, several.ok = TRUE)
    }

    if (missing(openApiType)) {
      # should this be an error?
      openApiType <- NULL
    } else {
      openApiType <- match.arg(openApiType)
    }

    if (missing(openApiFormat)) {
      openApiFormat <- NULL
    }

    preferredKey <- keys[[1]]

    entry <- list(
      preferredKey = preferredKey,
      location = location,
      openApiType = openApiType,
      openApiFormat = openApiFormat,
      # Q: Do we need to safe guard against special characters, such as `,`?
      # https://github.com/rstudio/plumber/pull/532#discussion_r439584727
      # A: https://swagger.io/docs/specification/serialization/
      # > Additionally, the allowReserved keyword specifies whether the reserved
      # > characters :/?#[]@!$&'()*+,;= in parameter values are allowed to be sent as they are,
      # > or should be percent-encoded. By default, allowReserved is false, and reserved characters
      # > are percent-encoded. For example, / is encoded as %2F (or %2f), so that the parameter
      # > value quotes/h2g2.txt will be sent as quotes%2Fh2g2.txt
      openApiRegex = openApiRegex,
      parser = parser,

      # TODO - not keen on these array functions
      # believe they are used only for comma separated arrays inside dynamic routes
      # - not sure Plumber needs to support these
      openApiRegexArray = paste0("(?:(?:", openApiRegex, "),?)+"),
      # TODO - this won't work for strings that contain commas?
      parserArray = function(x) {parser(stri_split_fixed(x, ",")[[1]])}
    )

    for (apiType in keys) {
      apiTypesInfo[[apiType]] <<- entry
    }

    invisible(TRUE)
  }

  addApiInfo(
    c("boolean", "bool", "logical"),
    openApiType = "boolean",
    openApiRegex = "[01tfTF]|true|false|TRUE|FALSE",
    parser = as.logical,
    location = c("query", "path")
  )

  addApiInfo(
    c("number", "numeric"),
    openApiType = "number",
    openApiRegex = "-?\\\\d*\\\\.?\\\\d+",
    parser = as.numeric,
    location = c("query", "path")
  )

  addApiInfo(
    c("double", "dbl"),
    openApiType = "number",
    openApiFormat = "double",
    openApiRegex = "-?\\\\d*\\\\.?\\\\d+",
    parser = as.numeric,
    location = c("query", "path")
  )

  addApiInfo(
    c("float"),
    openApiType = "number",
    openApiFormat = "float",
    openApiRegex = "-?\\\\d*\\\\.?\\\\d+",
    parser = as.numeric,
    location = c("query", "path")
  )

  addApiInfo(
    c("integer", "int"),
    openApiType = "integer",
    openApiFormat = "int64",
    openApiRegex = "-?\\\\d+",
    parser = as.integer,
    location = c("query", "path")
  )

  addApiInfo(
    c("string", "str", "chr", "character"),
    openApiType = "string",
    openApiRegex = "[^/]+",
    parser = as.character,
    location = c("query", "path")
  )

  # be careful not to trap lubridate on package installation
  lubridate_available <- function() {
    system.file(package = "lubridate") != "";
  }

  parse_datetime <- function(x) {
    if (lubridate_available()) lubridate::as_datetime(x) else as.Date.POSIXct(x)
  }

  parse_date <- function(x) {
    if (lubridate_available()) lubridate::as_date(x) else as.Date(x)
  }

  addApiInfo(
    c("date-time", "datetime"),
    openApiType = "string",
    # much more complex regexes are available... e.g. see https://stackoverflow.com/a/3143231/373321
    # (if importing one of those, remember to use cc attribution)
    openApiRegex = "\\\\d{4}-\\\\d{2}-\\\\d{2}T\\\\d{2}:\\\\d{2}:\\\\d{2}Z",
    openApiFormat = "date-time",
    parser = parse_datetime,
    location = c("query", "path")
  )

  addApiInfo(
    c("date", "Date"),
    openApiType = "string",
    # https://regex101.com/r/qH0sU7/1
    openApiRegex = "\\\\d{4}-\\\\d{2}-\\\\d{2}",
    openApiFormat = "date",
    parser = parse_date,
    location = c("query", "path")
  )

  addApiInfo(
    c("object", "list", "data.frame", "df", "object"),
    openApiType = "string",
    location = c("requestBody")
  )

  addApiInfo(
    c("file", "binary"),
    openApiType = "string",
    openApiFormat = "binary",
    location = c("requestBody")
  )
}


#' Parse the given plumber type and check it is a valid value
#' @noRd
plumberToApiType <- function(type, inPath = FALSE) {
  if (length(type) > 1) {
    return(vapply(type, plumberToApiType, character(1), inPath, USE.NAMES = FALSE))
  }

  # default type is "string" type
  if (is.na(type)) {
    return(defaultApiType)
  }

  apiType <- as.character(type)
  info <- apiTypesInfo[[apiType]]
  if (is.null(info)) {
    warning(
      "Unrecognized type: ", type, ". Using type: ", defaultApiType,
      call. = FALSE
    )
    apiType <- defaultApiType
  }  else  if (inPath && !"path" %in% info$location) {
    warning(
      "Unsupported path parameter type: ", type, ". Using type: ", defaultApiType,
      call. = FALSE
    )
    apiType <- defaultApiType
  } else {
    apiType <- info$preferredKey
  }

  return(apiType)
}

#' Filter OpenAPI Types
#' @noRd
filterApiTypes <- function(matches, property) {
  names(Filter(function(x) {any(matches %in% x[[property]])}, apiTypesInfo))
}
