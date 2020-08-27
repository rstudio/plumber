#' @post /user
function(req, id, name){
  list(
    id = id,
    name = name,
    body = req$body
    raw = req$bodyRaw
  )
}
