#* @errorhandler
function(req, res, err){
  stop("Caught")
}

#* @get /fail
function() {
  stop("fail")
  return("foo")
}
