

# calculate all OpenAPI Type information at once and use created information throughout package
apiTypesInfo <- list()
defaultApiType <- structure("string", default = TRUE)
defaultIsArray <- structure(FALSE, default = TRUE)

add_api_info_onLoad <- function() {
  addApiInfo <- function(
    keys,
    location = NULL, #c("body", "route", "query"),
    openApiType = NULL, # c("string", "number", "integer", "boolean", "object"),
    # note that openApiFormat is extensible - so match.arg should not be used on openApiFormat
    openApiFormat = NULL, #c("float", "double", "int32", "int64", "date", "date-time", "password", "byte", "binary"),
    openApiRegex  = NULL,
    parser = function(input) { input; }) {

    # TODO  - some match.arg stuff?

    preferredKey <- head(keys, 1)

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
      openApiRegexArray = paste0("(?:(?:", openApiRegex, "),?)+"),
      parser = parser,
      # TODO - this won't work for strings that contain commas?
      parserArray = function(x) {parser(stri_split_fixed(x, ",")[[1]])}
    )

    for (apiType in keys) {
      apiTypesInfo[[apiType]] <<- entry
    }

    invisible(TRUE)
  }

      # list(
      #   regex = regex,
      #   converter = converter,
      #   format = format,
      #   location = location,
      #   realType = apiType %||% realType,
      #   # Q: Do we need to safe guard against special characters, such as `,`?
      #   # https://github.com/rstudio/plumber/pull/532#discussion_r439584727
      #   # A: https://swagger.io/docs/specification/serialization/
      #   # > Additionally, the allowReserved keyword specifies whether the reserved
      #   # > characters :/?#[]@!$&'()*+,;= in parameter values are allowed to be sent as they are,
      #   # > or should be percent-encoded. By default, allowReserved is false, and reserved characters
      #   # > are percent-encoded. For example, / is encoded as %2F (or %2f), so that the parameter
      #   # > value quotes/h2g2.txt will be sent as quotes%2Fh2g2.txt
      #   regexArray = paste0("(?:(?:", regex, "),?)+"),
      #   converterArray = function(x) {converter(stri_split_fixed(x, ",")[[1]])}
      # )


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

  addApiInfo(
    c("date-time", "datetime"),
    openApiType = "string",
    # https://regex101.com/r/qH0sU7/1
    openApiRegex = "^((?:(\\d{4}-\\d{2}-\\d{2})T(\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?))(Z|[\\+-]\\d{2}:\\d{2})?)$",
    openApiFormat = "date-time",
    parser = lubridate::as_datetime,
    location = c("query", "path")
  )

  addApiInfo(
    c("date", "Date"),
    openApiType = "string",
    # https://regex101.com/r/qH0sU7/1
    openApiRegex = "^\\d{4}-\\d{2}-\\d{2}$",
    openApiFormat = "date",
    parser = lubridate::as_date,
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
