#* @filter logger
function(req){
  print(paste0(date(), " - ", req$REMOTE_ADDR, " - ",
               req$REQUEST_METHOD, " ", req$PATH_INFO))
  forward()
}

# The data.frame of all sales.
sales <- NULL

# Start incrementing our sales at ID = 0
id <- 0

#* POST a new transaction
#* @post /transaction
function(item, qty){
  # Increment ID
  id <<- id + 1

  sales <<- rbind(sales, data.frame(
    id = id,
    time = Sys.time(),
    item = item,
    qty = qty
  ))

  id
}

#* @get /transaction/plot
#* @png
function(id){
  if (is.null(sales) || nrow(sales) == 0){
    # No data to plot.
    plot(1,1, type="n", main="No sales yet :(")
    return()
  }
  plot(sales$time, cumsum(as.integer(sales$qty)),
       main="Purchases Over Time",
       xlab="Date", ylab="Qty", type="b")
}


#* Lookup transactions by ID
#* @get /transaction/<id:int>
function(id){
  sales[sales$id == id,]
}

#* Host the root page which includes a basic form to help test the POST
#* @get /
function(res){
  plumber::include_html("sales.html", res)
}

