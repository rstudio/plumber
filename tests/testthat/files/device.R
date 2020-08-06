#* @serializer png
#* @get /png
function() {
  plot(1:10)
}

#* @serializer jpeg
#* @get /jpeg
function() {
  plot(1:10)
}

#* @serializer svg
#* @get /svg
function() {
  plot(1:10)
}

#' @serializer png list(width = 150, height=150)
#' @get /littlepng
function(){
  plot(1:10)
}

#' @serializer jpeg list(width = 150, height=150)
#' @get /littlejpeg
function(){
  plot(1:10)
}

#* @serializer svg list(width=4, height=4)
#* @get /littlesvg
function() {
  warning("Should not test. Image size does not decrease with dimension decrease")
  plot(1:10)
}
