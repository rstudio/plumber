#' Convert router to/from OpenAPI specifications
#' @rdname openapi
#' @param plumber A plumber router or a plumbable file or directory
#' @description These functions are used to convert between OpenAPI
#' specifications and plumber file. Plumber only supports a limited
#' set of OpenAPI specifications.
#' @param output An optional filename where to write specifications.
#' @details OpenAPI is a specifications to describe API. More info
#' can be found at (https://www.openapis.org/)
#' @examples
#' pr <- plumber$new()
#' toOpenAPI(pr)
#' @export
toOpenAPI <- function(plumber, output = NULL) {
  if (!inherits(pr, "plumber")) {
    if (file.exists(plumber) && file.info(plumber)$isdir) {
      pr <- plumb(dir = plumber)
    } else {
      pr <- plumb(plumber)
    }
  }
  spec <- pr$openAPISpec()
  open_api_url <- {
    apiURL1 <- getOption("plumber.apiURL")
    apiURL2 <- urlHost(scheme = getOption("plumber.apiScheme", ""),
                       host   = getOption("plumber.apiHost", ""),
                       port   = getOption("plumber.apiPort", ""),
                       path   = getOption("plumber.apiPath", ""),
                       changeHostLocation = TRUE)
    priorizeProperty(apiURL1, apiURL2)
  }

  spec$servers$url <- open_api_url
  spec$servers$description <- "OpenAPI"

  spec <- toJSON(spec, auto_unbox = TRUE)
  if (!is.null(output)) {
    return(writeLines(spec, output))
  }
  return(spec)
}

#' @rdname openapi
#' @param openapi an OpenAPI specifications string, URL or file
#' @param con A connection object or a character string.
#' @param format Input file format. Either "json" or "yml". If not
#' provided, will be guessed from file extension.
#' @export
fromOpenAPI <- function(openapi, con = NULL, format = c("json", "yml")) {
  format <- match.arg(format)
  if (tools::file_ext(openapi) == "yml" || format == "yml") {
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("The yaml package is not available but is required in order to parse yaml specifications.\ninstall.packages(\"yaml\")",
           call. = FALSE)
    }
    if (stri_detect_fixed(openapi, "\n")) {
      spec <- yaml::yaml.load(openapi)
    } else {
      spec <- yaml::read_yaml(openapi)
    }
  } else if (jsonlite::validate(readLines(openapi, warn = FALSE))) {
    spec <- fromJSON(openapi)
  } else {
    stop("Invalid", format, "file.")
  }
  stubSpec(spec)
}

stubSpec <- function(spec) {

}

stubEndpoint <- function(spec) {

}

stubParameters <- function(spec) {

}

#' Mount OpenAPI spec to a plumber router
#' @noRd
mountOpenAPI <- function(pr, api_server_url) {

  spec <- pr$openAPISpec()

  # Create a function that's hardcoded to return the OpenAPI specification -- regardless of env.
  openapi_fun <- function(req) {
    # use the HTTP_REFERER so RSC can find the swagger location to ask
    ## (can't directly ask for 127.0.0.1)
    if (isFALSE(getOption("plumber.apiURL", FALSE)) &&
        isFALSE(getOption("plumber.apiHost", FALSE))) {
      if (is.null(req$HTTP_REFERER)) {
        # Prevent leaking host and port if option is not set
        api_server_url <- character(1)
      }
      else {
        # Use HTTP_REFERER as fallback
        api_server_url <- req$HTTP_REFERER
      }
    }

    modifyList(list(servers = list(list(url = api_server_url, description = "OpenAPI"))), spec)

  }
  # http://spec.openapis.org/oas/v3.0.3#document-structure
  # "It is RECOMMENDED that the root OpenAPI document be named: openapi.json or openapi.yaml."
  pr$handle("GET", "/openapi.json", openapi_fun, serializer = serializer_unboxed_json())
  if (requireNamespace("yaml", quietly = TRUE)) {
    pr$handle("GET", "/openapi.yaml", openapi_fun, serializer = serializer_yaml())
  }

  return(invisible())

}

#' Convert the endpoints as they exist on the router to a list which can
#' be converted into a openapi specification for these endpoints
#' @noRd
endpointSpecification <- function(routerEndpointEntry, path = routerEndpointEntry$path) {
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
    params <- parametersSpecification(routerEndpointEntry$params, pathParams, funcParams)

    resps <- responsesSpecification(routerEndpointEntry$responses)

    endptSpec <- list(
      summary = routerEndpointEntry$comments,
      responses = resps,
      parameters = params$parameters,
      requestBody = params$requestBody,
      tags = routerEndpointEntry$tags
    )

    ret[[cleanedPath]][[tolower(verb)]] <- endptSpec
  }

  ret
}

defaultResponse <- list(
  "default" = list(
    description = "Default response."
  )
)
responsesSpecification <- function(resps){
  if (is.null(resps) || is.na(resps)){
    resps <- defaultResponse
  } else if (!("default" %in% names(resps))){
    resps <- c(resps, defaultResponse)
  }
  resps
}

#' Extract the OpenAPI parameter specification from the endpoint
#' paramters.
#' @noRd
parametersSpecification <- function(endpointParams, pathParams, funcParams = NULL){

  params <- list(
    parameters = list(),
    requestBody = list()
  )
  inBody <- filterDataTypes("requestBody", "location")
  inRaw <- filterDataTypes("binary", "format")
  for (p in unique(c(names(endpointParams), pathParams$name, names(funcParams)))) {

    # Dealing with priorities endpointParams > pathParams > funcParams
    # For each p, find out which source to trust for :
    #   `type`, `serialization`, `required`
    # - `description` comes from endpointParams
    # - `serialization` defines both `style` and `explode`
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
      type <- priorizeProperty(defaultDataType,
                               pathParams[pathParams$name == p,]$type,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToDataType(type, inPath = TRUE)
      serialization <- priorizeProperty(defaultSerialization,
                                        pathParams[pathParams$name == p,]$serialization,
                                        endpointParams[[p]]$serialization,
                                        funcParams[[p]]$serialization)
    } else {
      location <- "query"
      style <- "form"
      explode <- TRUE
      type <- priorizeProperty(defaultDataType,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToDataType(type)
      serialization <- priorizeProperty(defaultSerialization,
                                        endpointParams[[p]]$serialization,
                                        funcParams[[p]]$serialization)
      required <- priorizeProperty(funcParams[[p]]$required,
                                   endpointParams[[p]]$required)
    }

    # Building OpenAPI specification
    if (type %in% inBody) {
      if (length(params$requestBody) == 0L) {
        params$requestBody$content$`application/json`[["schema"]] <-
          list(type = "object", properties = list())
      }
      property <- list(
        type = type,
        format = dataTypesInfo[[type]]$format,
        example = funcParams[[p]]$example,
        description = endpointParams[[p]]$desc
      )
      if (type %in% inRaw) {
        names(params$requestBody$content) <- "multipart/form-data"
        property$type <- dataTypesInfo[[type]]$realType
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
          format = dataTypesInfo[[type]]$format,
          default = funcParams[[p]]$default
        )
      )
      if (serialization) {
        paramList$schema <- list(
          type = "array",
          items = list(
            type = type,
            format = dataTypesInfo[[type]]$format
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

#' For openapi definition
#' @noRd
priorizeProperty <- function(...) {
  l <- list(...)
  isnullordefault <- sapply(l, function(x) {isNaOrNull(x) || isTRUE(attributes(x)$default)})
  l[[which.min(isnullordefault)]]
}

#' Check if x is JSON serializable (examples)
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
  args <- formals(eval(plumberExpression))
  lapply(args[!names(args) %in% c("...", "req", "res", "data")], function(arg) {
    required <- identical(arg, formals(function(x){})$x)
    if (is.call(arg) || is.name(arg)) {
      arg <- tryCatch(
        eval(arg),
        error = function(cond) {NA})
    }
    if (!is.logical(arg) && !is.numeric(arg) && !is.character(arg)
        && !(is.list(arg) && isJSONserializable(arg))) {
      arg <- NA
    }
    type <- if (isNaOrNull(arg)) {NA} else {typeof(arg)}
    type <- plumberToDataType(type)
    serialization <- {if (length(arg) > 1L && type %in% filterDataTypes(TRUE, "serializationSupport")) TRUE else defaultSerialization}
    list(
      default = arg,
      example = arg,
      required = required,
      serialization = serialization,
      type = type
    )
  })
}

isNa <- function(x) {
  if (is.list(x)) {
    return(FALSE)
  }
  is.na(x)
}

isNaOrNull <- function(x) {
  any(isNa(x)) || is.null(x)
}

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
