#* @get /
function(req, res){
  include_file("include/test.txt", res)
}

#* @get /html
function(req, res){
  include_html("include/test.html", res)
}

#* @get /rmd
function(req, res){
  include_rmd("include/test.Rmd", res)
}

#* @get /md
function(req, res){
  include_md("include/test.md", res)
}

