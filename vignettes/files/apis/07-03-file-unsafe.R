#' This is an example of an UNSAFE endpoint which
#' does not sanitize user input
#' @get /
function(file) {

  # An example of an UNSAFE endpoint.
  path <- file.path("./datasets", file)
  readLines(path)
}
