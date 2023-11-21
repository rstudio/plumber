

defaultErrorHandler <- function(){
  function(req, res, err){
    print(err)

    li <- list()

    # always serialize error with unboxed json
    res$serializer <- serializer_unboxed_json()

    if (res$status == 200L){
      # The default is a 200. If that's still set, then we should probably override with a 500.
      # It's possible, however, than a handler set a 40x and then wants to use this function to
      # render an error, though.
      res$status <- 500
      li$error <- "500 - Internal server error"
    } else {
      li$error <- "Internal error"
    }


    # Don't overly leak data unless they opt-in
    if (is.function(req$pr$getDebug) && isTRUE(req$pr$getDebug())) {
      li["message"] <- as.character(err)
    }

    li
  }
}

# this function works under the assumption that the regular route was not found.
# Here we are only trying to find if there are other routes that can be
#' @noRd
allowed_verbs <- function(pr, path_to_find) {

  verbs_allowed <- c()

  # look at all possible endpoints
  for (endpoint_group in pr$endpoints) {
    for (endpoint in endpoint_group) {
      if (endpoint$matchesPath(path_to_find)) {
        verbs_allowed <- c(verbs_allowed, endpoint$verbs)
      }
    }
  }

  # look at all possible mounts
  for (i in seq_along(pr$mounts)) {
    mount <- pr$mounts[[i]]
    mount_path <- sub("/$", "", names(pr$mounts)[i]) # trim trailing `/`

    # if the front of the urls don't match, move on to next mount
    if (!identical(
      substr(path_to_find, 1, nchar(mount_path)),
      mount_path
    )) {
      next
    }

    # remove path and recurse
    mount_path_to_find <- substr(path_to_find, nchar(mount_path) + 1, nchar(path_to_find))
    m_verbs <- allowed_verbs(mount, mount_path_to_find)

    # add any verbs found
    if (length(m_verbs) > 0) {
      verbs_allowed <- c(verbs_allowed, m_verbs)
    }
  }

  # return verbs
  sort(unique(verbs_allowed))
}

#' @noRd
is_405 <- function(pr, path_to_find, verb_to_find) {
  verbs_allowed <- allowed_verbs(pr, path_to_find)

  # nothing found, not 405
  if (length(verbs_allowed) == 0) return(FALSE)

  # is verb excluded?
  !(verb_to_find %in% verbs_allowed)
}
router_has_route <- function(pr, path_to_find, verb_to_find) {
  verbs_allowed <- allowed_verbs(pr, path_to_find)

  # nothing found, not a route
  if (length(verbs_allowed) == 0) return(FALSE)

  # is verb found?
  verb_to_find %in% verbs_allowed
}


default307Handler <- function(req, res, location) {
  res$status <- 307
  res$setHeader(
    name = "Location",
    value = location
  )
  res$serializer <- serializer_unboxed_json()

  list(message = "307 - Redirecting with trailing slash")
}

default404Handler <- function(req, res) {
  res$status <- 404
  res$serializer <- serializer_unboxed_json()
  list(error="404 - Resource Not Found")
}

default405Handler <- function(req, res) {
  res$status <- 405L
  # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Allow
  res$setHeader("Allow", paste(req$verbsAllowed, collapse = ", "))
  res$serializer <- serializer_unboxed_json()

  list(error = "405 - Method Not Allowed")
}


# When we want to end route execution and declare the route can not be handled,
# we check for:
# * trailing slash support (`307` redirect)
# * different verb support (`405` method not allowed)
# Then we return a 404 given `handle404(req, res)` (`404` method not found)
lastChanceRouteNotFound <- function(req, res, pr, handle404 = default404Handler) {

  # Try trailing slash route
  if (isTRUE(getOption("plumber.trailingSlash", FALSE))) {
    # Redirect to the slash route, if it exists
    path <- req$PATH_INFO
    # If the path does not end in a slash,
    if (!grepl("/$", path)) {
      new_path <- paste0(path, "/")
      # and a route with a slash exists...
      if (router_has_route(pr, new_path, req$REQUEST_METHOD)) {

        # Temp redirect with same REQUEST_METHOD
        # Add on the query string manually. They do not auto transfer
        # The POST body will be reissued by caller
        new_location <- paste0(new_path, req$QUERY_STRING)
        return(default307Handler(req, res, new_location))
      }
    }
  }

  # No trailing-slash route exists...
  # Try allowed verbs
  if (isTRUE(getOption("plumber.methodNotAllowed", TRUE))) {
    # Notify about allowed verbs
    if (is_405(pr, req$PATH_INFO, req$REQUEST_METHOD)) {
      return(default405Handler(req, res))
    }
  }

  # Handle 404 logic
  handle404(req = req, res = res)
}
