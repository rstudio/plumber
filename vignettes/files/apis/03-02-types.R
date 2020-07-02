#' @get /type/<id>
function(id){
  list(
    id = id,
    type = typeof(id)
  )
}
