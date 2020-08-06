emails <- data.frame(from=character(0), time=character(0), subject=character(0), stringsAsFactors = FALSE)

#* @post /mail
function(from, subject){
  emails <<- rbind(emails, data.frame(from=from, time=date(), subject=htmltools::htmlEscape(subject), stringsAsFactors=FALSE))
  TRUE
}

#* @get /tail
function(){
  tail(emails[,-1], n=5)
}
