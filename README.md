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
  a + b
}
```

Calling `RapierRouter$new("myfile.R")` would make your R function available as an API endpoint. You can visit this URL to run your R function and get the results.

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
