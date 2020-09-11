
is_available <- function (package, version = NULL) {
  installed <- nzchar(system.file(package = package))
  if (is.null(version)) {
    return(installed)
  }
  installed && isTRUE(utils::packageVersion(package) >= version)
}

`%||%` <- function(x, y) {
  if (is.null(x)) {
    y
  } else {
    x
  }
}

`%|%` <- function(x, y) {
  if (length(x) > 1) {
    stopifnot(length(y) == 1)
    x[is.na(x)] <- y
    return(x)
  }

  if (is.na(x)) {
    y
  } else {
    x
  }
}

once <- function(f) {
  called <- FALSE

  function() {
    if (!called) {
      called <<- TRUE
      f()
      invisible(TRUE)
    } else {
      invisible(FALSE)
    }
  }
}
