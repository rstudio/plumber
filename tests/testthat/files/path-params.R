#* @get /car/<id>
function(id){
  id
}

#* @get /car/<id>/sell/<price>
function(id, price){
  list(id=id, price=price)
}

#* @get /car/ratio/<ratio:double>
function(ratio){
  ratio
}

#* @get /car/sold/<sold:bool>
function(sold){
  sold
}

#* @post /car/<id>
function(req){
  req$args$id
}

#* @get /car/<id:int>/buy/<price>
function(id, price){
  list(id=id, price=price)
}
