#' @put /preferences
function(res, capital){
  if (missing(capital)){
    stop("You must specify a value for the 'capital' preference.")
  }
  res$setCookie("capitalize", capital)
}

#' @get /letter
function(req) {
  capitalize <- req$cookies$capitalize

  # Default to lower-case unless user preference is capitalized
  alphabet <- letters

  # The capitalize cookie will initially be empty (NULL)
  if (!is.null(capitalize) && capitalize == "1"){
    alphabet <- LETTERS
  }

  list(
    letter = sample(alphabet, 1)
  )
}
