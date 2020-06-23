

# calculate all OpenAPI Type information at once and use created information throughout package
apiTypesInfo <- list()
plumberToApiTypeMap <- list()
defaultApiType <- structure("string", default = TRUE)
defaultIsArray <- structure(FALSE, default = TRUE)

addApiInfo_onLoad <- function() {
  addApiInfo <- function(apiType, plumberTypes,
                         regex = NULL, converter = NULL,
                         format = NULL,
                         location = NULL,
                         realType = NULL,
                         arraySupport = FALSE) {
    apiTypesInfo[[apiType]] <<-
      list(
        regex = regex,
        converter = converter,
        format = format,
        location = location,
        arraySupport = arraySupport,
        realType = realType
      )

    if (arraySupport == TRUE) {
      apiTypesInfo[[apiType]] <<- utils::modifyList(
        apiTypesInfo[[apiType]],
        list(regexArray = paste0("(?:(?:", regex, "),?)+"),
             # Q: Do we need to safe guard against special characters, such as `,`?
             # https://github.com/rstudio/plumber/pull/532#discussion_r439584727
             # A: https://swagger.io/docs/specification/serialization/
             # > Additionally, the allowReserved keyword specifies whether the reserved
             # > characters :/?#[]@!$&'()*+,;= in parameter values are allowed to be sent as they are,
             # > or should be percent-encoded. By default, allowReserved is false, and reserved characters
             # > are percent-encoded. For example, / is encoded as %2F (or %2f), so that the parameter
             # > value quotes/h2g2.txt will be sent as quotes%2Fh2g2.txt
             converterArray = function(x) {converter(stri_split_fixed(x, ",")[[1]])})
      )
    }

    for (plumberType in plumberTypes) {
      plumberToApiTypeMap[[plumberType]] <<- apiType
    }
    # make sure it could be called again
    plumberToApiTypeMap[[apiType]] <<- apiType

    invisible(TRUE)
  }

  addApiInfo(
    "boolean",
    c("bool", "boolean", "logical"),
    "[01tfTF]|true|false|TRUE|FALSE",
    as.logical,
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addApiInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric,
    format = "double",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addApiInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer,
    format = "int64",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addApiInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character,
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addApiInfo(
    "object",
    c("list", "data.frame", "df"),
    location = "requestBody"
  )
  addApiInfo(
    "file",
    c("file", "binary"),
    location = "requestBody",
    format = "binary",
    realType = "string"
  )
}


#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToApiType <- function(type, inPath = FALSE) {
  if (length(type) > 1) {
    return(vapply(type, plumberToApiType, character(1), inPath, USE.NAMES = FALSE))
  }
  # default type is "string" type
  if (is.na(type)) {
    return(defaultApiType)
  }

  apiType <- plumberToApiTypeMap[[as.character(type)]]
  if (is.null(apiType)) {
    warning(
      "Unrecognized type: ", type, ". Using type: ", defaultApiType,
      call. = FALSE
    )
    apiType <- defaultApiType
  }
  if (inPath && !"path" %in% apiTypesInfo[[apiType]]$location) {
    warning(
      "Unsupported path parameter type: ", type, ". Using type: ", defaultApiType,
      call. = FALSE
    )
    apiType <- defaultApiType
  }

  return(apiType)
}

#' Filter OpenAPI Types
#' @noRd
filterApiTypes <- function(matches, property) {
  names(Filter(function(x) {any(matches %in% x[[property]])}, apiTypesInfo))
}
