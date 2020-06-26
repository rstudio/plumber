users <- data.frame(
  uid=c(12,13),
  username=c("kim", "john")
)

#' Lookup a user
#' @get /users/<id>
function(id){
  subset(users, uid==id)
}
