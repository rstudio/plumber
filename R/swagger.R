

# calculate all swagger type information at once and use created information throughout package
swaggerTypeInfo <- list()
plumberToSwaggerTypeMap <- list()
defaultSwaggerType <- "string"
attr(defaultSwaggerType, "default") <- TRUE
defaultSwaggerIsArray <- FALSE
attr(defaultSwaggerIsArray, "default") <- TRUE

local({
  addSwaggerInfo <- function(swaggerType, plumberTypes,
                             regex = NULL, converter = NULL,
                             format = NULL,
                             location = NULL,
                             realType = NULL,
                             arraySupport = FALSE) {
    swaggerTypeInfo[[swaggerType]] <<-
      list(
        regex = regex,
        converter = converter,
        format = format,
        location = location,
        arraySupport = arraySupport,
        realType = realType
      )

    if (arraySupport == TRUE) {
      swaggerTypeInfo[[swaggerType]] <<- modifyList(
        swaggerTypeInfo[[swaggerType]],
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
    as.logical,
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addSwaggerInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "-?\\\\d*\\\\.?\\\\d+",
    as.numeric,
    format = "double",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addSwaggerInfo(
    "integer",
    c("int", "integer"),
    "-?\\\\d+",
    as.integer,
    format = "int64",
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addSwaggerInfo(
    "string",
    c("chr", "str", "character", "string"),
    "[^/]+",
    as.character,
    location = c("query", "path"),
    arraySupport = TRUE
  )
  addSwaggerInfo(
    "object",
    c("list", "data.frame", "df"),
    location = "requestBody"
  )
  addSwaggerInfo(
    "file",
    c("file", "binary"),
    location = "requestBody",
    format = "binary",
    realType = "string"
  )
})


#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToSwaggerType <- function(type, inPath = FALSE) {
  if (length(type) > 1) {
    return(vapply(type, plumberToSwaggerType, character(1), inPath, USE.NAMES = FALSE))
  }
  # default type is "string" type
  if (is.na(type)) {
    return(defaultSwaggerType)
  }

  swaggerType <- plumberToSwaggerTypeMap[[as.character(type)]]
  if (is.null(swaggerType)) {
    warning(
      "Unrecognized type: ", type, ". Using type: ", defaultSwaggerType,
      call. = FALSE
    )
    swaggerType <- defaultSwaggerType
  }
  if (inPath && !"path" %in% swaggerTypeInfo[[swaggerType]]$location) {
    warning(
      "Unsupported path parameter type: ", type, ". Using type: ", defaultSwaggerType,
      call. = FALSE
    )
    swaggerType <- defaultSwaggerType
  }

  return(swaggerType)
}

#' Check if swagger type supports array
#' @noRd
supportsArray <- function(swaggerTypes) {
  vapply(
    swaggerTypeInfo[swaggerTypes],
    `[[`,
    logical(1),
    "arraySupport",
    USE.NAMES = FALSE)
}

#' Filter swagger type
#' @noRd
filterSwaggerTypes <- function(matches, property) {
  names(Filter(function(x) {any(matches %in% x[[property]])}, swaggerTypeInfo))
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
  # Get the params from endpoint func
  funcParams <- routerEndpointEntry$getFuncParams()
  for (verb in routerEndpointEntry$verbs) {
    params <- extractSwaggerParams(routerEndpointEntry$params, pathParams, funcParams)

    # If we haven't already documented a path param, we should add it here.
    # FIXME: warning("Undocumented path parameters: ", paste0())

    resps <- extractResponses(routerEndpointEntry$responses)

    endptSwag <- list(
      summary = routerEndpointEntry$comments,
      responses = resps,
      parameters = params$parameters,
      requestBody = params$requestBody,
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
extractSwaggerParams <- function(endpointParams, pathParams, funcParams = NULL){

  params <- list(
    parameters = list(),
    requestBody = list()
  )
  inBody <- filterSwaggerTypes("requestBody", "location")
  inRaw <- filterSwaggerTypes("binary", "format")
  for (p in unique(c(names(endpointParams), pathParams$name, names(funcParams)))) {

    # Dealing with priorities endpointParams > pathParams > funcParams
    # For each p, find out which source to trust for :
    #   `type`, `isArray`, `required`
    # - `description` comes from endpointParams
    # - `isArray` defines both `style` and `explode`
    # - `default` and `example` comes from funcParams
    # - `location` change to "path" when p is in pathParams and
    #   unused when `type` is "object" or "file"
    # - When type is `object`, create a requestBody with content
    #   default to "application/json"
    # - When type is `file`, change requestBody content to
    #   multipart/form-data

    if (p %in% pathParams$name) {
      location <- "path"
      required <- TRUE
      style <- "simple"
      explode <- FALSE
      type <- priorizeProperty(defaultSwaggerType,
                               pathParams[pathParams$name == p,]$type,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToSwaggerType(type, inPath = TRUE)
      isArray <- priorizeProperty(defaultSwaggerIsArray,
                                  pathParams[pathParams$name == p,]$isArray,
                                  endpointParams[[p]]$isArray,
                                  funcParams[[p]]$isArray)
    } else {
      location <- "query"
      style <- "form"
      explode <- TRUE
      type <- priorizeProperty(defaultSwaggerType,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToSwaggerType(type)
      isArray <- priorizeProperty(defaultSwaggerIsArray,
                                  endpointParams[[p]]$isArray,
                                  funcParams[[p]]$isArray)
      required <- priorizeProperty(funcParams[[p]]$required,
                                   endpointParams[[p]]$required)
    }

    # Building openapi definition
    if (type %in% inBody) {
      if (length(params$requestBody) == 0L) {
        params$requestBody$content$`application/json`[["schema"]] <-
          list(type = "object", properties = list())
      }
      property <- list(
        type = type,
        format = swaggerTypeInfo[[type]]$format,
        example = funcParams[[p]]$example,
        description = endpointParams[[p]]$desc
      )
      if (type %in% inRaw) {
        names(params$requestBody$content) <- "multipart/form-data"
        property$type <- swaggerTypeInfo[[type]]$realType
      }
      params$requestBody[[1]][[1]][[1]]$properties[[p]] <- property
      if (required) { params$requestBody[[1]][[1]][[1]]$required <-
        c(p, params$requestBody[[1]][[1]][[1]]$required)}
    } else {
      paramList <- list(
        name = p,
        description = endpointParams[[p]]$desc,
        `in` = location,
        required = required,
        schema = list(
          type = type,
          format = swaggerTypeInfo[[type]]$format,
          default = funcParams[[p]]$default
        )
      )
      if (isArray) {
        paramList$schema <- list(
          type = "array",
          items = list(
            type = type,
            format = swaggerTypeInfo[[type]]$format
          ),
          default = funcParams[[p]]$default
        )
        paramList$style <- style
        paramList$explode <- explode
      }
      params$parameters[[length(params$parameters) + 1]] <- paramList
    }

  }
  params
}

#' Check na
#' @noRd
isNa <- function(x) {
  if (is.list(x)) {
    return(FALSE)
  }
  is.na(x)
}

#' Check na or null
#' @noRd
isNaOrNull <- function(x) {
  any(isNa(x)) || is.null(x)
}

#' Remove na or null
#' @noRd
removeNaOrNulls <- function(x) {
  # preemptively stop
  if (!is.list(x)) {
    return(x)
  }
  if (length(x) == 0) {
    return(x)
  }
  # Prevent example from being wiped out
  if (!isNaOrNull(x$example)) {
    saveExample <- TRUE
    savedExample <- x$example
    x$example <- NULL
  } else {
    saveExample <- FALSE
  }

  # remove any `NA` or `NULL` elements
  toRemove <- vapply(x, isNaOrNull, logical(1))
  if (any(toRemove)) {
    x[toRemove] <- NULL
  }

  # recurse through list
  ret <- lapply(x, removeNaOrNulls)
  class(ret) <- class(x)

  # Put example back in
  if (saveExample) {
    ret$example <- savedExample
  }

  ret
}

#' For openapi definition
#' @noRd
priorizeProperty <- function(...) {
  l <- list(...)
  if (length(l) > 0L) {
    isnullordefault <- vapply(l, function(x) {isNaOrNull(x) || isTRUE(attributes(x)$default)}, logical(1))
    # return the position of the first FALSE value or position 1 if all values are TRUE
    return(l[[which.min(isnullordefault)]])
  }
  return()
}

#' Check if x is JSON serializable
#' @noRd
isJSONserializable <- function(x) {
  testJSONserializable <- TRUE
  tryCatch(toJSON(x),
           error = function(cond) {
             # Do we need to test for specific errors?
             testJSONserializable <<- FALSE}
  )
  testJSONserializable
}

#' Extract metadata on args of plumberExpression
#' @noRd
getArgsMetadata <- function(plumberExpression){
  #return same format as getTypedParams or params?
  if (!is.function(plumberExpression)) plumberExpression <- eval(plumberExpression)
  args <- formals(plumberExpression)
  lapply(args[!names(args) %in% c("...", "res", "req")], function(arg) {
    required <- rlang::is_missing(arg)
    if (is.call(arg) || is.name(arg)) {
      arg <- tryCatch(
        eval(arg),
        error = function(cond) {NA})
    }
    # Check that it is possible to transform arg value into
    # an example for the openAPI spec. Valid transform are
    # either a logical, a numeric, a character or a list that
    # is json serializable. Otherwise set to NA. Otherwise
    # it
    if (!is.logical(arg) && !is.numeric(arg) && !is.character(arg)
        && !(is.list(arg) && isJSONserializable(arg))) {
      message("Argument of class ", class(arg), " cannot be used to set default value in OpenAPI specifications.")
      arg <- NA
    }
    type <- if (isNaOrNull(arg)) {NA} else {typeof(arg)}
    type <- plumberToSwaggerType(type)
    list(
      default = arg,
      example = arg,
      required = required,
      isArray = {if (length(arg) > 1L & supportsArray(type)) TRUE else defaultSwaggerIsArray},
      type = type
    )
  })
}
