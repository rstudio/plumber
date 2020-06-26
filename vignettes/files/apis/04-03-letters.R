#' Get letters after a given letter
#' @get /boxed
function(letter="A"){
  LETTERS[LETTERS > letter]
}

#' Get letters after a given letter
#' @serializer unboxedJSON
#' @get /unboxed
function(letter="A"){
  LETTERS[LETTERS > letter]
}
