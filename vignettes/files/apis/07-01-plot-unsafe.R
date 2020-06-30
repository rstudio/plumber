#' This is an example of an UNSAFE endpoint which
#' is vulnerable to a DOS attack.
#' @get /
#' @png
function(pts=10) {
  # An example of an UNSAFE endpoint.
  plot(1:pts)
}
