values <- 15

MAX_VALS <- 50

#* Append to our values
#* @post /append
function(val, res){
  v <- as.numeric(val)
  if (is.na(v)){
    res$status <- 400
    res$body <- "val parameter must be a number"
  }
  values <<- c(values, val)

  if (length(values) > MAX_VALS){
    values <<- tail(values, n=MAX_VALS)
  }

  list(result="success")
}

#* Get the last few values
#* @get /tail
function(n="10", res){
  n <- as.numeric(n)
  if (is.na(n) || n < 1 || n > MAX_VALS){
    res$status <- 400
    res$body <- "parameter 'n' must be a number between 1 and 100"
  }

  list(val=tail(values, n=n))
}

#* Get a graph of the values
#* @png
#* @get /graph
function(){
  plot(values, type="b", ylim=c(1,100), main="Recent Values")
}
