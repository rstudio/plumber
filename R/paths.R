# Taken from shiny
# @author shiny authors
resolve_path <- function(dir, relpath) {
  abs.path <- file.path(dir, relpath)
  if (!file.exists(abs.path))
    return(NULL)
  abs.path <- normalizePath(abs.path, winslash='/', mustWork=TRUE)
  dir <- normalize_dir_path(dir)
  if (nchar(abs.path) <= nchar(dir) + 1)
    return(NULL)
  if (substr(abs.path, 1, nchar(dir)) != dir ||
      substr(abs.path, nchar(dir)+1, nchar(dir)+1) != '/') {
    return(NULL)
  }
  return(abs.path)
}

normalize_dir_path <- function(dir) {
  dir <- normalizePath(dir, winslash = '/', mustWork = TRUE)
  # trim the possible trailing slash under Windows (#306)
  if (isWindows()) {
    dir <- sub('/$', '', dir)
  }
  dir
}
