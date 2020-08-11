default404Handler <- function(req, res){
  if (is_405(req$pr, req$PATH_INFO, req$REQUEST_METHOD)) {
    res$status <- 405L
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Allow
    res$setHeader("Allow", paste(req$verbsAllowed, collapse = ", "))
    return(list(error = "405 - Method Not Allowed"))
  }
  res$status <- 404
  list(error="404 - Resource Not Found")
}

defaultErrorHandler <- function(){
  function(req, res, err){
    print(err)

    li <- list()

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
    if (is.function(req$pr$get_debug) && isTRUE(req$pr$get_debug())) {
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

  !(verb_to_find %in% verbs_allowed)
}
