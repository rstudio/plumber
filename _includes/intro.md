
<div class="row"><div class="col-sm-8 col-sm-offset-2" markdown="1">

# Introduction

plumber allows you to create a REST API by merely decorating your existing R source code with special comments. Take a look at an example.

{% highlight r %}
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
{% endhighlight %}

These comments allow plumber to make your R functions available as API endpoints. You can either prefix the comments with `#*` or `#'` but we recommend the former since `#'` will conflict with the Roxygen package.

{% highlight r %}
> library(plumber)
> r <- plumb("plumber.R")  # Where 'plumber.R' is the location of the file shown above
> r$run(port=8000)
{% endhighlight %}

You can visit this URL using a browser or a terminal to run your R function and get the results. For instance [http://localhost:8000/plot](http://localhost:8000/plot) will show you a histogram, and [http://localhost:8000/echo?msg=hello](http://localhost:8000/echo?msg=hello) will echo back the 'hello' message you provided.

Here we're using `curl` via a Mac/Linux terminal.

{% highlight bash %}
$ curl "http://localhost:8000/echo"
 {"msg":["The message is: ''"]}
$ curl "http://localhost:8000/echo?msg=hello"
 {"msg":["The message is: 'hello'"]}
{% endhighlight %}

As you might have guessed, the request's query string parameters are forwarded to the R function as arguments (as character strings).

{% highlight bash %}
$ curl --data "a=4&b=3" "http://localhost:8000/sum"
 [7]
{% endhighlight %}

If you're still interested, check out our [more thorough documentation](/docs/endpoints/).

## Installation

You can install the latest stable version from CRAN using the following command:

{% highlight bash %}
install.packages("plumber")
{% endhighlight %}

If you want to try out the latest development version, you can install it from GitHub. The easiest way to do that is by using `devtools`.

{% highlight bash %}
devtools::install_github("trestletech/plumber")
{% endhighlight %}


</div></div>
