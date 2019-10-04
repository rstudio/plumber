
# Visit /future
# While /future is loading, visit /sync many times

library(promises)
library(future)

future::plan("multiprocess")


#' @get /sync
function() {
  paste0("sync: ", Sys.time())
}

#' @get /future
function() {
  future({
    Sys.sleep(10)
    paste0("future: ", Sys.time())
  })
}
