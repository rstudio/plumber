# calculate all OpenAPI type information at once and use created information throughout package
dataTypesInfo <- list()
dataTypesMap <- list()
defaultDataType <- structure("string", default = TRUE)
defaultSerialization <- structure(FALSE, default = TRUE)

local({
  addDataTypeInfo <- function(dataType, plumberTypes,
                              regex = NULL, converter = NULL,
                              regexSerialization = NULL,
                              converterSerialization = NULL,
                              format = NULL,
                              location = NULL,
                              realType = NULL) {
    dataTypesInfo[[dataType]] <<-
      list(
        regex = regex, regexSerialization = regexSerialization,
        converter = converter, converterSerialization = converterSerialization,
        format = format,
        location = location,
        serializationSupport = !is.null(regexSerialization) & !is.null(converterSerialization),
        realType = realType
      )

    for (plumberType in plumberTypes) {
      dataTypesMap[[plumberType]] <<- dataType
    }
    # make sure it could be called again
    dataTypesMap[[dataType]] <<- dataType

    invisible(TRUE)
  }

  addDataTypeInfo(
    "boolean",
    c("bool", "boolean", "logical"),
    "[01tfTF]|true|false|TRUE|FALSE",
    as.logical,
    "(?:(?:[01tfTF]|true|false|TRUE|FALSE),?)+",
    function(x) {as.logical(stri_split_fixed(x, ",")[[1]])},
    location = c("query", "path")
  )
  addDataTypeInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric,
    "(?:-?\\\\d*\\\\.?\\\\d+,?)+",
    function(x) {as.numeric(stri_split_fixed(x, ",")[[1]])},
    format = "double",
    location = c("query", "path")
  )
  addDataTypeInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer,
    "(?:-?\\\\d+,?)+",
    function(x) {as.integer(stri_split_fixed(x, ",")[[1]])},
    format = "int64",
    location = c("query", "path")
  )
  addDataTypeInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character,
    "(?:[^/,]+,?)",
    function(x) {as.character(stri_split_fixed(x, ",")[[1]])},
    location = c("query", "path")
  )
  addDataTypeInfo(
    "object",
    c("list", "data.frame", "df"),
    location = "requestBody"
  )
  addDataTypeInfo(
    "file",
    c("file", "binary"),
    location = "requestBody",
    format = "binary",
    realType = "string"
  )
})

#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToDataType <- function(type, inPath = FALSE) {
  if (length(type) > 1) {
    return(vapply(type, plumberToDataType, character(1), inPath, USE.NAMES = FALSE))
  }
  # default type is "string" type
  if (is.na(type)) {
    return(defaultDataType)
  }

  dataType <- dataTypesMap[[as.character(type)]]
  if (is.null(dataType)) {
    warning(
      "Unrecognized type: ", type, ". Using type: ", defaultDataType,
      call. = FALSE
    )
    dataType <- defaultDataType
  }
  if (inPath && !"path" %in% dataTypesInfo[[dataType]]$location) {
    warning(
      "Unsupported path parameter type: ", type, ". Using type: ", defaultDataType,
      call. = FALSE
    )
    dataType <- defaultDataType
  }

  return(dataType)
}

#' Filter data type, return dataTypes where `matches` is found in `property`
#' @noRd
filterDataTypes <- function(matches, property) {
  names(Filter(function(x) {any(matches %in% x[[property]])}, dataTypesInfo))
}
