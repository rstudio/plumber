#* @filter something
function(req){
  req$args$hello <- 23
}

#*@filter nospace
function(){

}

#* @get /
function(req){
  req$args$hello
}
