#* @png
#* @get /png
function() {
  plot(1:10)
}

#* @jpeg
#* @get /jpeg
function() {
  plot(1:10)
}

#* @svg
#* @get /svg
function() {
  plot(1:10)
}

#' @png (width = 150, height=150)
#' @get /littlepng
function(){
  plot(1:10)
}

#' @jpeg (width = 150, height=150)
#' @get /littlejpeg
function(){
  plot(1:10)
}

#* @svg(width=4, height=4)
#* @get /littlesvg
function() {
  warning("Should not test. Image size does not decrease with dimension decrease")
  plot(1:10)
}
