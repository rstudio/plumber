#' @serializer custom
#' @get /
function(){
  1
}

#' @filter foo
#' @serializer custom2
function(req, res){
  if (req$PATH_INFO != '/filter-catch'){
    forward()
  }
}
