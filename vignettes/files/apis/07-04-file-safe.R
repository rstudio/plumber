#' This is an example of an endpoint which
#' checks user input.
#' @get /
function(file) {
  # Strip all "non-word" characters from user input
  sanitizedFile <- gsub("\\W", "", file)

  path <- file.path("./datasets", sanitizedFile)
  readLines(path)
}
