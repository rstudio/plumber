library(plumber)
library(feather)

# Illustration of binary uploads and post-processing of the file on receipt.
# As a proof of concept we use a feather file: test.feather


# To upload and use the content of the file in a function:
# curl -X POST http://localhost:9080/upload -F 'myfile=@test.feather'

#* @post /upload
function(name, data) {
  # work with binary files after upload 
  # in this example a feather file
  content <- read_feather(data)
  return(content)
}


# To upload and use the properties of the file in a function:
# curl -X POST http://localhost:9080/inspect -F 'myfile=@test.feather'

#* @post /inspect
function(name, data) {
  file_info <- data.frame(
    filename = name,
    mtime = file.info(data)$mtime,
    ctime = file.info(data)$ctime
    )

  return(file_info)
}
