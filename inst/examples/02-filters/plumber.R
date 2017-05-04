library(plumber)

users <- data.frame(
  id=1:2,
  username=c("joe", "kim"),
  groups=c("users", "admin,users")
)

#* Filter that grabs the "username" querystring parameter.
#* You should, of course, use a real auth system, but
#* this shows the principles involved.
#* @filter auth-user
function(req, username=""){
  # Since username is a querystring param, we can just
  # expect it to be available as a parameter to the
  # filter (plumber magic).

  # This is a work-around for https://github.com/trestletech/plumber/issues/12
  # and shouldn't be necessary long-term
  req$user <- NULL

  if (username == ""){
    # No username provided
  } else if (username %in% users$username){
    # username is valid

    req$user <- users[users$username == username,]

  } else {
    # username was provided, but invalid
    stop("No such username: ", username)
  }

  # Continue on
  forward()
}

#* Now require that all users must be authenticated.
#* @filter require-auth
function(req, res){
  if (is.null(req$user)){
    # User isn't logged in

    res$status <- 401 # Unauthorized
    list(error="You must login to access this resource.")
  } else {
    # user is logged in. Move on...
    forward()
  }
}

#* @get /me
function(req){
  # Safe to assume we have a user, since we've been
  # through all the filters and would have gotten an
  # error earlier if we weren't.
  list(user=req$user)
}

#* Get info about the service. We preempt the
#* require-auth filter because we want authenticated and
#* unauthenticated users alike to be able to access this
#* endpoint.
#* @preempt require-auth
#* @get /about
function(){
  list(descript="This is a demo service that uses authentication!")
}
