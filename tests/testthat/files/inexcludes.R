#' @exclude exc
#' @include inc
#' @get test
#' Should be captured.
function(){

}

#' Should not be captured
#' @include inc2
function(){

}

#' @exclude exc1
#' Should capture multiple
#' @include inc
#' @exclude exc2
#' @delete /
function(){

}

#' @exclude exc1
#' @exclude exc2
#' @exclude exc3
#' @post here
function(){

}
