#' This is an example of an safe endpoint which
#' checks user input to avoid a DOS attack
#' @get /
#' @png
function(pts=10) {
  if (pts > 1000){
    stop("pts must be < 1,000")
  }

  plot(1:pts)
}
