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
    res$serializer <- jsonSerializer()
  }
  forward()
}

#* @get /something
function(){
  4
}

#* @get /another
function(req, res){
  res$serializer <-  function(val, req, res, errorHandler){
    list(status=201L, headers=list(), body="CUSTOM3")
  }
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
