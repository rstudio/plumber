a <- 13
15

#* Some docs
#* @get /
function(req, res, forward){
  x <- 2
  x + a
}

#* Moar docs
#* @post /
useless <- function(req, res, forward){
  y <- 3
  y + a
}
