

# calculate all swagger type information at once and use created information throughout package
swaggerTypeInfo <- list()
plumberToSwaggerTypeMap <- list()
defaultSwaggerType <- "string"

local({
  addSwaggerInfo <- function(swaggerType, plumberTypes, regex, converter) {
    swaggerTypeInfo[[swaggerType]] <<-
      list(
        regex = regex,
        converter = converter
      )


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
    "(?:(?:[01tfTF]|true|false|TRUE|FALSE),?)+",
    function(x) {as.logical(stringi::stri_split_fixed(x, ",")[[1]])}
  )
  addSwaggerInfo(
    "number",
    c("dbl", "double", "float", "number", "numeric"),
    "(?:-?\\\\d*\\\\.?\\\\d+,?)+",
    function(x) {as.numeric(stringi::stri_split_fixed(x, ",")[[1]])}
  )
  addSwaggerInfo(
    "integer",
    c("int", "integer"),
    "(?:-?\\\\d+,?)+",
    function(x) {as.integer(stringi::stri_split_fixed(x, ",")[[1]])}
  )
  addSwaggerInfo(
    "string",
    c("chr", "str", "character", "string"),
    "(?:[^/,]+,?)",
    function(x) {as.character(stringi::stri_split_fixed(x, ",")[[1]])}
  )
  addSwaggerInfo(
    "object",
    c("list", "data.frame", "df"),
    "(?:[^/,]+,?)",
    # Should not be used, object in path are not reliable for larger size like a serialized iris datasets
    # Errors on Windows with a chopped up req$PATH_INFO only containing the last few thousands character
    # Could not reproduce on Ubuntu. Might be related to rewriting buffer in httpuv from the split url
    # did not investigate further.
    function(x) {safeFromJSON(URLdecode(x))}
  )
})


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
    warning(
      "Unrecognized type: ", type, ". Using type: ", defaultSwaggerType,
      call. = FALSE
    )
    swaggerType <- defaultSwaggerType
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
extractSwaggerParams <- function(endpointParams, pathParams){

  params <- list(
    parameters = list(),
    requestBody = list()
  )
  for (p in names(endpointParams)) {
    location <- "query"
    required <- endpointParams[[p]]$required
    style <- "form"
    explode <- "true"
    if (p %in% pathParams$name) {
      location <- "path"
      required <- "true"
      style <- "simple"
      explode <- "false"
    }

    type <- endpointParams[[p]]$type
    if (isNaOrNull(type)) {
      if (location == "path") {
        type <- plumberToSwaggerType(pathParams$type[pathParams$name == p])
      } else {
        type <- defaultSwaggerType
      }
    }

    if (type == "object") {
      if (length(params$requestBody) == 0L) {
        params$requestBody <- list(
          content = list(
            `application/json` = list(
              schema = list(
                type = object,
                example = list()
              )
            )
          )
        )
      }
      params$requestBody$content$`application/json`$schema$example[[p]] <- {
        if (endpointParams[[p]]$serialization) {"[{}]"} else {"{}"}
      }
    } else {
      paramList <- list(
        name = p,
        description = endpointParams[[p]]$desc,
        `in` = location,
        required = required,
        schema = list(
          type = type
        )
      )
      if (endpointParams[[p]]$serialization) {
        paramList$schema <- list(
          type = "array",
          items = list(
            type = type
          ),
          minItems = 1
        )
        paramList$style <- style
        paramList$explode <- explode
      }
      params$parameters[[length(params$parameters) + 1]] <- paramList
    }

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
