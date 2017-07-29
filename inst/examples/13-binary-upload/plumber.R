library(plumber)
library(feather)

#* @post /upload
function(name, data) {
  # work with binary files after upload 
  # in this example a feather file
  content <- read_feather(data)
  return(content)
}

#* @post /inspect
function(name, data) {
  file_info <- data.frame(
    filename = name,
    mtime = file.info(data)$mtime,
    ctime = file.info(data)$ctime
    )

  return(file_info)
}
