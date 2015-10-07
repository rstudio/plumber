#* @filter foo
function(req){
  req$args$hello <- 13
}

#* @get /
function(hello){
  hello
}
