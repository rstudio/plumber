# Introduction

plumber allows you to create a REST API by merely decorating your existing R source code with special comments. Take a look at an example.

{% highlight r %}
# myfile.R

#! @get /mean
normalMean <- function(samples=10){
  data <- rnorm(samples)
  mean(data)
}

#! @post /sum
addTwo <- function(a, b){
  as.numeric(a) + as.numeric(b)
}
{% endhighlight %}

These comments allow plumber to make your R functions available as API endpoints. You can either prefix the comments with `#!` or `#'` but we recommend the former since `#'` will conflict with the Roxygen package.

{% highlight r %}
> library(plumber)
> r <- plumb("myfile.R")  # Where 'myfile.R' is the location of the file shown above
> r$run(port=8000)
{% endhighlight %}

You can visit this URL using a browser or a terminal to run your R function and get the results. Here we're using `curl` via a Mac/Linux terminal.

{% highlight bash %}
$ curl "http://localhost:8000/mean"
 [-0.254]
$ curl "http://localhost:8000/mean?samples=10000"
 [-0.0038]
{% endhighlight %}

As you might have guessed, the request's query string parameters are forwarded to the R function as arguments (as character strings).

{% highlight bash %}
$ curl --data "a=4&b=3" "http://localhost:8000/sum"
 [7]
{% endhighlight %}

If you're still interested, check out our [live, more thorough example](/docs/endpoints/)

## Installation

Currently plumber is not available on CRAN, so you'll need to install it from GitHub. The easiest way to do that is by using `devtools`.

{% highlight bash %}
library(devtools)
install_github("trestletech/plumber")
library(plumber)
{% endhighlight %}

