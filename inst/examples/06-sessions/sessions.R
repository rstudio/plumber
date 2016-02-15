#* @get /counter
function(req, res){
  count <- 0
  if (!is.null(req$cookies$visitcounter)){
    count <- as.numeric(req$cookies$visitcounter)
  }
  res$setCookie("visitcounter", count+1)
  return(paste0("This is visit #", count))
}
