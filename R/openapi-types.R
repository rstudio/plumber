# calculate all OpenAPI type information at once and use created information throughout package
dataTypesInfo <- list()
dataTypesMap <- list()
defaultDataType <- structure("string", default = TRUE)
defaultIsArray <- structure(FALSE, default = TRUE)

local({
  addDataTypeInfo <- function(dataType, plumberTypes,
                              regex = NULL, converter = NULL,
                              format = NULL,
                              location = NULL,
                              realType = NULL,
                              arraySupport = FALSE) {
    dataTypesInfo[[dataType]] <<-
      list(
        regex = regex,
        converter = converter,
        format = format,
        location = location,
        arraySupport = arraySupport,
        realType = realType
      )

    if (arraySupport == TRUE) {
      dataTypesInfo[[dataType]] <<- modifyList(
        dataTypesInfo[[dataType]],
        list(regexArray = paste0("(?:(?:", regex, "),?)+"),
             converterArray = function(x) {converter(stri_split_fixed(x, ",")[[1]])})
      )
    }

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
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addDataTypeInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric,
    format = "double",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addDataTypeInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer,
    format = "int64",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addDataTypeInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character,
    location = c("query", "path"),
    arraySupport = TRUE
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
