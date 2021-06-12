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
function(req, res, type="") {
  if (type == "json"){
    res$serializer <- plumber:::serializer_json()
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
#* @serializer json
function(){
  "JSON"
}

#* @get /short-html
#* @serializer html
function(){
  "HTML"
}

#* @get /single-arg-ser
#* @serializer customOneArg list(single="hi there")
function(){
  "COA"
}

#* @get /multi-arg-ser
#* @serializer   customMultiArg list(first=LETTERS[1], second=4+4, third=4.3)
function(){
  "MAS"
}
