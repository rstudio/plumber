#' @get /
function(req, res){
  include_file("files/include/test.txt", res)
}

#' @get /html
function(req, res){
  include_html("files/include/test.html", res)
}

#' @get /rmd
function(req, res){
  include_rmd("files/include/test.Rmd", res)
}

#' @get /md
function(req, res){
  include_md("files/include/test.md", res)
}

