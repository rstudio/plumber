
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


#* Write and return multiple files as an archive. Ex: `datasets.zip`
#* @serializer octet
#* @get /datasets
function() {

  # Create temporary directory structure
  rnd_dir <- rawToChar(as.raw(sample(65:90, size = 5, replace = TRUE)))
  tmp_dir <- file.path(tempdir(), rnd_dir)
  dir.create(tmp_dir, showWarnings = FALSE)
  on.exit(unlink(tmp_dir, recursive = TRUE), add = TRUE)

  # Save datasets to csv
  csv_files <- character()
  for (dataset in c("mtcars", "iris", "airquality")) {
    csv_file <- file.path(tmp_dir, paste0(dataset, ".csv"))
    csv_files <- c(csv_files, csv_file)
    write.csv(get(dataset), csv_file)
  }

  # Create archive
  zip_file <- file.path(tmp_dir, "datasets.zip")
  zip(zip_file, csv_files, flags = "-jq9X")
  val <- readBin(zip_file, "raw", file.info(zip_file)$size)

  as_attachment(val, "datasets.zip")

}
