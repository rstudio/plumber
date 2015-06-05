
#' @get /
#' @prior __first__
function(){
  "first"
}

#' @get /abc
function(){
  "abc get"
}

#' @post /abc
function(){
  "abc post"
}

#' @filter filt1
function(req, res){

}

#' @filter filt2
function(req, res){

}

#' @use /dog
#' @prior filt2
function(){
  "dog use"
}

#' @get /dog
#' @prior filt1
function(){
  "dog get"
}

#' @get /error
function(){
  stop("ERROR")
}
