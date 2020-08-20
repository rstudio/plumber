
is_available <- function (package, version = NULL) {
  installed <- nzchar(system.file(package = package))
  if (is.null(version)) {
    return(installed)
  }
  installed && isTRUE(utils::packageVersion(package) >= version)
}
