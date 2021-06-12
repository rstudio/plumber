
# Causes arguments to be evaluated for matching purposes
#* @post /body
function(x = 1) {
  x
}

#* @post /postBody
function(req) {
  req$postBody
}
