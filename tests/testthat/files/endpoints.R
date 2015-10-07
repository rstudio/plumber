#* @stuff
#* @more- stuff
#*
#* comments
function(req, res, forward){
  4
}

#* @get /test
#* @post /test
#* @more stuff
#* hey
foo <- function(a, b, ..., req, res, forward){
  5
}

#* Not an API
#* @param things
foo <- function(req, res, forward){
  6
}

#* @post /
#* one line
function(req, res, forward){x <- 9; x + 1}

#* Spaces in between
#* @delete /

function(req, res, forward){
  x <- 10
  x + 2
}

#*@get nowhitespace
function(req, res, forward){
  14
}
