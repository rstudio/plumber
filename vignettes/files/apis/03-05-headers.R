#' Return the value of a custom header
#' @get /
function(req){
  list(
    val = req$HTTP_CUSTOMHEADER
  )
}
