# rapier

rapier allows you to create a REST API by merely decorating your R source code with special annotations. Take a look at an example.

```r
# myFile.R

#' @get /mean
normalMean <- function(samples=10){
  data <- rnorm(samples)
  mean(data)
}

#' @post /sum
addTwo <- function(a, b){
  as.numeric(a) + as.numeric(b)
}
```

These annotations allow rapier to make your R functions available as API endpoints. 

```r
r <- RapierRouter$new("myfile.R") # Where 'myfile.R' is the location of the file shown above
serve(r, port=8000)
```

You can visit this URL using a browser or a terminal to run your R function and get the results. Here we're using `curl` via a Mac/Linux terminal.

```
$ curl "http://localhost:8000/mean"
  [-0.254]
$ curl "http://localhost:8000/mean?samples=10000"
  [-0.0038]
```  

As you might have guessed, the request's query string parameters are forwarded to the R function as arguments (as character strings).

```
$ curl --data "a=4&b=3" "http://localhost:8000/sum"
  [7]
```
