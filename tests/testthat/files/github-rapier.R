#' Get information about the currently available
#' @get /version
function(){
  desc <- read.dcf(system.file("DESCRIPTION", package="rapier"))
  list(
    version = unname(desc[1,"Version"]),
    built = unname(desc[1,"Built"]),
    sha1 = unname(desc[1,"GithubSHA1"])
  )
}

#' Give GitHub Webhook a way to alert us about new pushes to the repo
#' https://developer.github.com/webhooks/
#' @post /update
function(req){
  print(req)
}
