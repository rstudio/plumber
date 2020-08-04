
#* Save a file with a particular file name. Ex: `time.txt`
#* @serializer text
#* @get /name
function() {
  as_attachment(Sys.time(), "time.txt")
}



#* Save a file as the route. Ex: `no_name`
#* @serializer text
#* @get /no_name
function() {
  as_attachment(Sys.time())
}

#* Display within browser. Possible as the mime type is `text/plain`
#* @serializer text
#* @get /inline
function() {
  Sys.time()
}
