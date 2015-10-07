#* @serializer custom
#* @get /
function(){
  1
}

#* @filter foo
#* @serializer custom2
function(req, res){
  if (req$PATH_INFO != '/filter-catch'){
    forward()
  }
}

#* @filter foo2
function(req, res, type=""){
  if (type == "json"){
    res$serializer <- "json"
  }
  forward()
}

#* @get /something
function(){
  4
}

#* @get /another
function(req, res){
  res$serializer <- "custom2"
  5
}

#* @get /short-json
#* @json
function(){
  "JSON"
}

#* @get /short-html
#* @html
function(){
  "HTML"
}
