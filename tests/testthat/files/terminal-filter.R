
#* @filter terminal
function(){
  # We don't call forward(), implying that we've terminated the request within
  # this filter.
  1
}

#* @get /
function(){
  2
}
