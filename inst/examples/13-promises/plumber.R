library(promises)

#' @get /async
function(){
  promise(function(resolve, reject){
    resolve("async")
  })
}

#' @get /sync
function(){
  "sync"
}

#' @get /async-bad
function(){
  promise(function(resolve, reject){
    reject("error here")
  })
}

#' @get /bad
function(){
  stop("sync error")
}
