# Global code; gets executed at plumb() time.
counter <- 0

#' @get /
function(){
  # Only gets evaluated when this endpoint is requested.
  counter <<- counter + 1
}
