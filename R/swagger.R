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

prepareSwaggerEndpoints <- function(routerEndpoints){
  endpoints <- list()

  for (fil in routerEndpoints){
    for (e in fil){
      # TODO: we are sensitive to trailing slashes. Should we be?
      # cleanedPath <- gsub("/$", "", e$path)
      cleanedPath <- gsub("<([^:>]+)(:[^>]+)?>", "{\\1}", e$path)
      if (is.null(endpoints[[cleanedPath]])){
        endpoints[[cleanedPath]] <- list()
      }

      # Get the params from the path
      pathParams <- e$getTypedParams()
      for (verb in e$verbs){
        params <- data.frame(name=character(0),
                             description=character(0),
                             `in`=character(0),
                             required=logical(0),
                             type=character(0), check.names = FALSE)

        for (p in names(e$params)){
          location <- "query"
          if (p %in% pathParams$name){
            location <- "path"
          }

          type <- e$params[[p]]$type
          if (is.na(type)){
            if (location == "path") {
              type <- pathParams[pathParams$name == p,"type"]
            } else {
              type <- "string" # Default to string
            }
          }

          parDocs <- data.frame(name = p,
                                description = e$params[[p]]$desc,
                                `in`=location,
                                type=type,
                                required=e$params[[p]]$required,
                                check.names = FALSE,
                                required=FALSE)

          if (location == "path"){
            parDocs$required <- TRUE
          }

          params <- rbind(params, parDocs)
        }

        # If we haven't already documented a path param, we should add it here.
        # FIXME: warning("Undocumented path parameters: ", paste0())

        resps <- e$responses
        defaultResp <- list("default"=list(description="Default response."))
        if (is.null(resps)){
          resps <- defaultResp
        } else if (!("default" %in% names(resps))){
          resps <- c(resps, defaultResp)
        }

        endptSwag <- list(summary=e$comments,
                          responses=resps,
                          parameters=params)

        endpoints[[cleanedPath]][[tolower(verb)]] <- endptSwag

      }
    }
  }

  endpoints
}
