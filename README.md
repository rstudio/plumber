# plumber

[![Build Status](https://travis-ci.org/trestletech/plumber.svg?branch=master)](https://travis-ci.org/trestletech/plumber)
[![](https://www.r-pkg.org/badges/version/plumber)](https://www.r-pkg.org/pkg/plumber)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/plumber?color=brightgreen)](https://www.r-pkg.org/pkg/plumber)
[![codecov](https://codecov.io/gh/trestletech/plumber/branch/master/graph/badge.svg)](https://codecov.io/gh/trestletech/plumber)

<img align="right" src="https://www.rplumber.io/components/images/plumber.png" />

Plumber allows you to create a web API by merely decorating your existing R source code with special comments. Take a look at an example.

```r
# plumber.R

#* @get /mean
normalMean <- function(samples=10){
  data <- rnorm(samples)
  mean(data)
}

#* @post /sum
addTwo <- function(a, b){
  as.numeric(a) + as.numeric(b)
}
```

These comments allow plumber to make your R functions available as API endpoints. You can use either `#*` as the prefix or `#'`, but we recommend the former since `#'` will collide with Roxygen. 

```r
> library(plumber)
> r <- plumb("plumber.R")  # Where 'plumber.R' is the location of the file shown above
> r$run(port=8000)
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

You can also send your data as JSON:

```
$ curl --data '{"a":4, "b":5}' http://localhost:8000/sum
 [9]
```

## Installation

You can install the latest stable version from CRAN using the following command:

```r
install.packages("plumber")
```

If you want to try out the latest development version, you can install it from GitHub. The easiest way to do that is by using `devtools`.

```r
library(devtools)
install_github("trestletech/plumber")
library(plumber)
```

## Hosting

If you're just getting started with hosting cloud servers, the DigitalOcean integration included in plumber will be the best way to get started. You'll be able to get a server hosting your custom API in just two R commands. Full documentation is available at https://www.rplumber.io/docs/digitalocean/.

A couple of other approaches to hosting plumber are also made available:

 - PM2 - https://www.rplumber.io/docs/hosting/
 - Docker - https://www.rplumber.io/docs/docker/

## Related Projects

- [OpenCPU](https://www.opencpu.org/) - A server designed for hosting R APIs with an eye towards scientific research.
- [jug](http://bart6114.github.io/jug/index.html) - *(development discontinued)* an R package similar to Plumber but uses a more programmatic approach to constructing the API.

## Provenance

plumber was originally released as the `rapier` package and has since been renamed (7/13/2015).
