

# calculate all swagger type information at once and use created information throughout package
swaggerTypeInfo <- (function() {
  swaggerTypes <- c()
  swaggerTypeToRegexMap <- list()
  swaggerTypeToConvertersMap <- list()
  plumberToSwaggerTypeMap <- list()

  addSwaggerInfo <- function(swaggerType, plumberTypes, regex, converter) {
    swaggerTypes[length(swaggerTypes) + 1] <<- swaggerType

    swaggerTypeToRegexMap[[swaggerType]] <<- regex

    swaggerTypeToConvertersMap[[swaggerType]] <<- converter

    for (plumberType in plumberTypes) {
      plumberToSwaggerTypeMap[[plumberType]] <<- swaggerType
    }
    # make sure it could be called again
    plumberToSwaggerTypeMap[[swaggerType]] <<- swaggerType

    invisible(TRUE)
  }

  addSwaggerInfo(
    "boolean",
    c("bool", "boolean", "logical"),
    "[01tfTF]|true|false|TRUE|FALSE",
    as.logical
  )
  addSwaggerInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric
  )
  addSwaggerInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer
  )
  addSwaggerInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character
  )

  list(
    swaggerTypes = swaggerTypes,
    defaultSwaggerType = "string",
    swaggerTypeToRegexMap = swaggerTypeToRegexMap,
    swaggerTypeToConvertersMap = swaggerTypeToConvertersMap,
    plumberToSwaggerTypeMap = plumberToSwaggerTypeMap
  )
})()

swaggerTypeToRegexMap <- swaggerTypeInfo$swaggerTypeToRegexMap
swaggerTypeToConvertersMap <- swaggerTypeInfo$swaggerTypeToConvertersMap
plumberToSwaggerTypeMap <- swaggerTypeInfo$plumberToSwaggerTypeMap
defaultSwaggerType <- swaggerTypeInfo$defaultSwaggerType


#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToSwaggerType <- function(type) {
  if (length(type) > 1) {
    return(vapply(type, plumberToSwaggerType, character(1)))
  }
  # default type is "string" type
  if (is.na(type)) {
    return(defaultSwaggerType)
  }

  swaggerType <- plumberToSwaggerTypeMap[[as.character(type)]]
  if (is.null(swaggerType)) {
    stop("Unrecognized type: ", type)
  }

  return(swaggerType)
}

#' Convert the endpoints as they exist on the router to a list which can
#' be converted into a swagger definition for these endpoints
#' @noRd
prepareSwaggerEndpoint <- function(routerEndpointEntry, path = routerEndpointEntry$path) {
  ret <- list()

  # We are sensitive to trailing slashes. Should we be?
  # Yes - 12/2018
  cleanedPath <- gsub("<([^:>]+)(:[^>]+)?>", "{\\1}", path)
  ret[[cleanedPath]] <- list()

  # Get the params from the path
  pathParams <- routerEndpointEntry$getTypedParams()
  for (verb in routerEndpointEntry$verbs) {
    params <- extractSwaggerParams(routerEndpointEntry$params, pathParams)

    # If we haven't already documented a path param, we should add it here.
    # FIXME: warning("Undocumented path parameters: ", paste0())

    resps <- extractResponses(routerEndpointEntry$responses)

    endptSwag <- list(
      summary = routerEndpointEntry$comments,
      responses = resps,
      parameters = params,
      tags = routerEndpointEntry$tags
    )

    ret[[cleanedPath]][[tolower(verb)]] <- endptSwag
  }

  ret
}

defaultResp <- list(
  "default" = list(
    description = "Default response."
  )
)
extractResponses <- function(resps){
  if (is.null(resps) || is.na(resps)){
    resps <- defaultResp
  } else if (!("default" %in% names(resps))){
    resps <- c(resps, defaultResp)
  }
  resps
}

#' Extract the swagger-friendly parameter definitions from the endpoint
#' paramters.
#' @noRd
extractSwaggerParams <- function(endpointParams, pathParams){

  params <- list()
  for (p in names(endpointParams)) {
    location <- "query"
    if (p %in% pathParams$name) {
      location <- "path"
    }

    type <- endpointParams[[p]]$type
    if (isNaOrNull(type)){
      if (location == "path") {
        type <- plumberToSwaggerType(pathParams$type[pathParams$name == p])
      } else {
        type <- defaultSwaggerType
      }
    }

    paramList <- list(
      name = p,
      description = endpointParams[[p]]$desc,
      `in` = location,
      required = endpointParams[[p]]$required,
      schema = list(
        type = type
      )
    )

    if (location == "path"){
      paramList$required <- TRUE
    }

    params[[length(params) + 1]] <- paramList

  }
  params
}


isNa <- function(x) {
  if (is.list(x)) {
    return(FALSE)
  }
  is.na(x)
}
isNaOrNull <- function(x) {
  isNa(x) || is.null(x)
}
removeNaOrNulls <- function(x) {
  # preemptively stop
  if (!is.list(x)) {
    return(x)
  }
  if (length(x) == 0) {
    return(x)
  }

  # remove any `NA` or `NULL` elements
  toRemove <- vapply(x, isNaOrNull, logical(1))
  if (any(toRemove)) {
    x[toRemove] <- NULL
  }

  # recurse through list
  ret <- lapply(x, removeNaOrNulls)
  class(ret) <- class(x)

  ret
}
