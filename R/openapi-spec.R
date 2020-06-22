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

  spec <- jsonlite::toJSON(spec, auto_unbox = TRUE)
  if (!is.null(output)) {
    return(writeLines(spec, output))
  }
  return(spec)
}

#' @rdname openapi
#' @param openapi an OpenAPI specifications string, URL or file
#' @param format Input file format. Either "json" or "yml". If not
#' provided, will be guessed from file extension.
#' @export
fromOpenAPI <- function(openapi, format = c("json", "yaml")) {
  format <- match.arg(format)
  spec <- new.env()
  # if (tools::file_ext(openapi) == "yaml" || format == "yaml") {
  #   if (!requireNamespace("yaml", quietly = TRUE)) {
  #     stop("The yaml package is not available but is required in order to parse yaml specifications.\ninstall.packages(\"yaml\")",
  #          call. = FALSE)
  #   }
  #   if (stringi::stri_detect_fixed(openapi, "\n")) {
  #     s <- yaml::yaml.load(openapi)
  #   } else {
  #     s <- yaml::read_yaml(openapi)
  #   }
  # } else {
    s <- jsonlite::fromJSON(openapi)
  # }
  mapply(assign, names(s), s, MoreArgs = list(envir = spec))
  return(spec)
  #stubSpec(spec)
}

#' @
stubSpec <- function(spec) {
  l <- function(lines, value, field) {
    if (is.null(value)) return(lines)
    line <- paste0("#* @api", field, " ", value)
    c(lines, lines)}
  options("plumber.apiURL" = spec$servers[[1]]$url)
  lines <- character()
  lines <- l(lines, spec$info$title, "Title")
  lines <- l(lines, spec$info$description, "Description")
  lines <- l(lines, spec$info$termsOfService, "TOS")
  lines <- l(lines, spec$info$contact$name, "ContactName")
  lines <- l(lines, spec$info$contact$email, "ContactEmail")
  lines <- l(lines, spec$info$contact$url, "ContactUrl")
  lines <- l(lines, spec$info$license$name, "LicenseName")
  lines <- l(lines, spec$info$license$url, "LicenseUrl")
  lines <- l(lines, spec$info$version, "Version")

  a <- c("title","description", "termsOfService", "contact", "license", "version", "bob")
  b <- c("Title","Description","TOS","Contact","License", "Version", "Bobby")
  line <- paste0("#* @api", b, " ", spec$info[a])
}

stubEndpoint <- function(spec) {

}

stubParameters <- function(spec) {

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

    # If we haven't already documented a path param, we should add it here.
    # FIXME: warning("Undocumented path parameters: ", paste0())

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
      type <- priorizeProperty(defaultDataType,
                               pathParams[pathParams$name == p,]$type,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToDataType(type, inPath = TRUE)
      isArray <- priorizeProperty(defaultIsArray,
                                  pathParams[pathParams$name == p,]$isArray,
                                  endpointParams[[p]]$isArray,
                                  funcParams[[p]]$isArray)
    } else {
      location <- "query"
      style <- "form"
      explode <- TRUE
      type <- priorizeProperty(defaultDataType,
                               endpointParams[[p]]$type,
                               funcParams[[p]]$type)
      type <- plumberToDataType(type)
      isArray <- priorizeProperty(defaultIsArray,
                                  endpointParams[[p]]$isArray,
                                  funcParams[[p]]$isArray)
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
      if (isArray) {
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
  if (length(l) > 0L) {
    isnullordefault <- vapply(l, function(x) {isNaOrNull(x) || isTRUE(attributes(x)$default)}, logical(1))
    # return the position of the first FALSE value or position 1 if all values are TRUE
    return(l[[which.min(isnullordefault)]])
  }
  NULL # do not return any value
}

#' Check if x is JSON serializable
#' @noRd
isJSONserializable <- function(x) {
  tryCatch(
    {
      toJSON(x)
      TRUE
    },
    error = function(cond) {
      # Do we need to test for specific errors?
      FALSE
    }
  )
}

#' Extract metadata on args of plumberExpression
#' @noRd
getArgsMetadata <- function(plumberExpression){
  #return same format as getTypedParams or params?
  if (!is.function(plumberExpression)) plumberExpression <- eval(plumberExpression)
  args <- formals(plumberExpression)
  lapply(args[!names(args) %in% c("...", "req", "res")], function(arg) {
    required <- identical(arg, formals(function(x){})$x)
    if (is.call(arg) || is.name(arg)) {
      arg <- tryCatch(
        eval(arg, envir = environment(plumberExpression)),
        error = function(cond) {NA})
    }
    # Check that it is possible to transform arg value into
    # an example for the openAPI spec. Valid transform are
    # either a logical, a numeric, a character or a list that
    # is json serializable. Otherwise set to NA.
    if (!is.logical(arg) && !is.numeric(arg) && !is.character(arg)
        && !(is.list(arg) && isJSONserializable(arg))) {
      message("Argument of class ", class(arg), " cannot be used to set default value in OpenAPI specifications.")
      arg <- NA
    }
    type <- if (isNaOrNull(arg)) {NA} else {typeof(arg)}
    type <- plumberToDataType(type)
    isArray <- {if (length(arg) > 1L && type %in% filterDataTypes(TRUE, "arraySupport")) TRUE else defaultIsArray}
    list(
      default = arg,
      example = arg,
      required = required,
      isArray = isArray,
      type = type
    )
  })
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
