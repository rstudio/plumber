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

#* Download a binary file.
#* @serializer contentType list(type="application/octet-stream")
#* @get /download-binary
function(res){
  # TODO: Stream the data into the response rather than loading it all in memory
  # first.

  # Create a temporary example RDS file
  x <- list(a=123, b="hi!")
  tmp <- tempfile(fileext=".rds")
  saveRDS(x, tmp)

  # This header is a convention that instructs browsers to present the response
  # as a download named "mydata.Rds" rather than trying to render it inline.
  res$setHeader("Content-Disposition", "attachment; filename=mydata.Rds")

  # Read in the raw contents of the binary file
  bin <- readBin(tmp, "raw", n=file.info(tmp)$size)

  # Delete the temp file
  file.remove(tmp)

  # Return the binary contents
  bin
}


