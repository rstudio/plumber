#' @post /user
function(req, id, name){
  list(
    id = id,
    name = name,
    raw = req$postBody
  )
}
