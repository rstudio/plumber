#' Get information about the currently available
#' @get /version
function(){
  desc <- read.dcf(system.file("DESCRIPTION", package="rapier"))
  resp <- list(
    version = unname(desc[1,"Version"]),
    built = unname(desc[1,"Built"])
  )

  if ("GithubSHA1" %in% colnames(desc)){
    resp["sha1"] <- unname(desc[1,"GithubSHA1"])
  }

}

list_to_string <- function(the_list) {
  cnames <- names(the_list)
  allvalues <- lapply(cnames, function(name) {
    item <- the_list[[name]]
    if (is.list(item)) {
      if (is.null(names(item))) {
        paste(name, "[[", seq_along(item), "]] = ", item, sep = "", collapse = "<br />")
      } else {
        paste(name, "$", names(item), " = ", item, sep = "", collapse = "<br />")
      }
    } else if (is.environment(item)){
      paste(name, "ENV", sep=" = ")
    } else if (is.character(item) || is.numeric(item)){
      paste(name, as.character(item), sep=" = ")
    }
    else {
      paste(name, "?", sep=" = ")
    }
  })
  paste(allvalues, collapse = "<br />")
}

env_to_list <- function(env){
  vars <- ls(envir=env)
  res <- lapply(vars, function(var){
    print(var)
    val <- get(var, envir=env)
    if (is.list(val)){
      return(list_to_string(val))
    } else if (is.environment(val)){
      return ("<environment>")
    } else{
      return(val)
    }
  })
  names(res) <- vars
  list_to_string(res)
}

#' Give GitHub Webhook a way to alert us about new pushes to the repo
#' https://developer.github.com/webhooks/
#' @post /update
function(req){
  saveRDS(req, file="req.Rds")
  print(env_to_list(req))

  1
}
