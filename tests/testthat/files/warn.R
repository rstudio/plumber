
#* @get /warning
function(res){
  warning("this is a warning")
  res$status <- (options("warn")[[1]])
}
