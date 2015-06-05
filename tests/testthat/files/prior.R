testFun <- function(){
  1
}
testFun2 <- function(){
  2
}
testFun3 <- function(){
  3
}

#' @prior testFun
#' @get /
function(){

}

#' @prior test
#' Excluded
function(){

}

#' @prior testFun2
#' @get /
#'

function(){

}

#'@prior testFun3
#'@post /
function(){

}
