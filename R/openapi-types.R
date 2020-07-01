

# calculate all OpenAPI Type information at once and use created information throughout package
apiTypesInfo <- list()
plumberToApiTypeMap <- list()
defaultApiType <- structure("string", default = TRUE)
defaultIsArray <- structure(FALSE, default = TRUE)

add_api_info_onLoad <- function() {
  addApiInfo <- function(apiType, plumberTypes,
                         regex = NULL, converter = NULL,
                         format = NULL,
                         location = NULL,
                         realType = NULL) {
    apiTypesInfo[[apiType]] <<-
      list(
        regex = regex,
        converter = converter,
        format = format,
        location = location,
        realType = realType,

        regexArray = paste0("(?:(?:", regex, "),?)+"),
        converterArray = function(x) {converter(stri_split_fixed(x, ",")[[1]])}
      )

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
    location = c("query", "path")
  )
  addApiInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric,
    format = "double",
    location = c("query", "path")
  )
  addApiInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer,
    format = "int64",
    location = c("query", "path")
  )
  addApiInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character,
    location = c("query", "path")
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
