#* This is an example of an safe endpoint which
#* checks user input to avoid a DOS attack
#* @get /
#* @serializer png
function(pts=10) {
  if (pts > 1000 & pts > 0){
    stop("pts must be between 1 and 1,000")
  }

  plot(1:pts)
}
