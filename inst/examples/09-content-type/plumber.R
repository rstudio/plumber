#* @serializer contentType list(type="application/pdf")
#* @get /pdf
function(){
  tmp <- tempfile()
  pdf(tmp)
  plot(1:10, type="b")
  text(4, 8, "PDF from plumber!")
  dev.off()

  readBin(tmp, "raw", n=file.info(tmp)$size)
}

#* @serializer contentType list(type="text/plain")
#* @get /text
function(){
  "just plain text here..."
}

#* @serializer contentType list(type="text/html")
#* @get /html
function(){
  "<html><h1>HTML!</h1>HTML here!</html>"
}



