# plumber-logger.R

#! @filter logger
function(req){
  print(paste0(date(), " - ", req$REMOTE_ADDR, " - ",
               req$REQUEST_METHOD, " ", req$PATH_INFO))
  forward()
}

#! @get /
#! @post /
function(){
  return("response here")
}
