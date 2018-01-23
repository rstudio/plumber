#' Parse the given plumber type and return the typecast value
#' @noRd
plumberToSwaggerType <- function(type){
  if (type == "bool" || type == "logical"){
    return("boolean")
  } else if (type == "double" || type == "numeric"){
    return("number")
  } else if (type == "int"){
    return("integer")
  } else if (type == "character"){
    return("string")
  } else {
    stop("Unrecognized type: ", type)
  }
}

#' Convert the endpoints as they exist on the router to a list which can
#' be converted into a swagger definition for these endpoints
#' @noRd
prepareSwaggerEndpoints <- function(routerEndpoints){
  endpoints <- list()

  for (fil in routerEndpoints){
    for (e in fil){
      # TODO: we are sensitive to trailing slashes. Should we be?
      cleanedPath <- gsub("<([^:>]+)(:[^>]+)?>", "{\\1}", e$path)
      if (is.null(endpoints[[cleanedPath]])){
        endpoints[[cleanedPath]] <- list()
      }

      # Get the params from the path
      pathParams <- e$getTypedParams()
      for (verb in e$verbs){
        params <- extractSwaggerParams(e$params, pathParams)

        # If we haven't already documented a path param, we should add it here.
        # FIXME: warning("Undocumented path parameters: ", paste0())

        resps <- extractResponses(e$responses)

        endptSwag <- list(summary=e$comments,
                          responses=resps,
                          parameters=params,
                          tags=e$tags)

        endpoints[[cleanedPath]][[tolower(verb)]] <- endptSwag
      }
    }
  }

  endpoints
}

defaultResp <- list("default"=list(description="Default response."))
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
  params <- data.frame(name=character(0),
                       description=character(0),
                       `in`=character(0),
                       required=logical(0),
                       type=character(0),
                       check.names = FALSE,
                       stringsAsFactors = FALSE)
  for (p in names(endpointParams)){
    location <- "query"
    if (p %in% pathParams$name){
      location <- "path"
    }

    type <- endpointParams[[p]]$type
    if (is.null(type) || is.na(type)){
      if (location == "path") {
        type <- plumberToSwaggerType(pathParams[pathParams$name == p,"type"])
      } else {
        type <- "string" # Default to string
      }
    }

    parDocs <- data.frame(name = p,
                          description = endpointParams[[p]]$desc,
                          `in`=location,
                          required=endpointParams[[p]]$required,
                          type=type,
                          check.names = FALSE,
                          stringsAsFactors = FALSE)

    if (location == "path"){
      parDocs$required <- TRUE
    }

    params <- rbind(params, parDocs)
  }
  params
}
