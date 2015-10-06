#! @get /car/:id
function(id){
  id
}

#! @get /car/:id/sell/:price
function(id, price){
  list(id=id, price=price)
}

#! @post /car/:id
function(req){
  req$args$id
}
