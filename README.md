# plumber

[![Build Status](https://travis-ci.org/rstudio/plumber.svg?branch=master)](https://travis-ci.org/rstudio/plumber)
[![](https://www.r-pkg.org/badges/version/plumber)](https://www.r-pkg.org/pkg/plumber)
[![CRAN RStudio mirror downloads](https://cranlogs.r-pkg.org/badges/plumber?color=brightgreen)](https://www.r-pkg.org/pkg/plumber)
[![codecov](https://codecov.io/gh/trestletech/plumber/branch/master/graph/badge.svg)](https://codecov.io/gh/trestletech/plumber)

<img align="right" src="https://www.rplumber.io/components/images/plumber-broken.png" />

Plumber allows you to create a web API by merely decorating your existing R
source code with special comments. Take a look at an example.

```r
# plumber.R

#* Echo back the input
#* @param msg The message to echo
#* @get /echo
function(msg=""){
  list(msg = paste0("The message is: '", msg, "'"))
}

#* Plot a histogram
#* @png
#* @get /plot
function(){
  rand <- rnorm(100)
  hist(rand)
}

#* Return the sum of two numbers
#* @param a The first number to add
#* @param b The second number to add
#* @post /sum
function(a, b){
  as.numeric(a) + as.numeric(b)
}
```

These comments allow plumber to make your R functions available as API
endpoints. You can use either `#*` as the prefix or `#'`, but we recommend the
former since `#'` will collide with Roxygen.

```r
> library(plumber)
> r <- plumb("plumber.R")  # Where 'plumber.R' is the location of the file shown above
> r$run(port=8000)
```

You can visit this URL using a browser or a terminal to run your R function and
get the results. For instance
[http://localhost:8000/plot](http://localhost:8000/plot) will show you a
histogram, and
[http://localhost:8000/echo?msg=hello](http://localhost:8000/echo?msg=hello)
will echo back the 'hello' message you provided.

Here we're using `curl` via a Mac/Linux terminal.

```
$ curl "http://localhost:8000/echo"
 {"msg":["The message is: ''"]}
$ curl "http://localhost:8000/echo?msg=hello"
 {"msg":["The message is: 'hello'"]}
```

As you might have guessed, the request's query string parameters are forwarded
to the R function as arguments (as character strings).

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

If you want to try out the latest development version, you can install it from
GitHub. The easiest way to do that is by using `devtools`.

```r
library(devtools)
install_github("trestletech/plumber")
library(plumber)
```

## Hosting

If you're just getting started with hosting cloud servers, the
[DigitalOcean](https://www.digitalocean.com) integration included in plumber
will be the best way to get started. You'll be able to get a server hosting your
custom API in just two R commands. Full documentation is available at
https://www.rplumber.io/docs/digitalocean/.

[RStudio Connect](https://www.rstudio.com/products/connect/) is a commercial
publishing platform that enables R developers to easily publish a variety of R
content types, including Plumber APIs. Additional documentation is available at
https://www.rplumber.io/docs/hosting.html#rstudio-connect.

A couple of other approaches to hosting plumber are also made available:

 - PM2 - https://www.rplumber.io/docs/hosting/
 - Docker - https://www.rplumber.io/docs/docker/
 
## Related Projects

- [OpenCPU](https://www.opencpu.org/) - A server designed for hosting R APIs
  with an eye towards scientific research.
- [jug](http://bart6114.github.io/jug/index.html) - *(development discontinued)*
  an R package similar to Plumber but uses a more programmatic approach to
  constructing the API.

## Provenance

plumber was originally released as the `rapier` package and has since been
renamed (7/13/2015).
