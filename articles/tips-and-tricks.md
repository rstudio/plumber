# Tips & Tricks

![](files/images/plumber_broken.png)

## Debugging

If you’ve historically used R interactively, you may find it difficult
to define functions that get executed at once without your input as
Plumber requires. There are a couple of debugging techniques to be aware
of when working on your Plumber APIs; these techniques are equally
transferable to debugging your R scripts, packages, or reports.

### Print Debugging

Most programmers first approach debugging by adding print statements to
their code in order to inspect the state at some point. In R,
[`print()`](https://rdrr.io/r/base/print.html) or
[`cat()`](https://rdrr.io/r/base/cat.html) can be used to print out some
state. For instance, `cat("i is currently: ", i)` could be inserted in
your code to help you ensure that the variable `i` is what it should be
at that point in your code.

This approach is equally viable with Plumber. When developing your
Plumber API in an interactive environment, this debugging output will be
logged to the same terminal where you called `run()` on your API. In a
non-interactive production environment, these messages will be included
in the API server logs for later inspection.

### Router Stage Debugging

Similar to print debugging, we can output what plumber knows at each
stage of the processing pipeline. You can do this by adding
[hooks](https://www.rplumber.io/articles/programmatic-usage.html#router-hooks)
to two key stages: `"postroute"` and `"postserialize"`.

For example, we can add these lines to our `plumber.R` file:

``` r
#* @plumber
function(pr) {
  pr %>%
    pr_hook("postroute", function(req, value) {
      # Print stage information
      str(list(
        stage = "postroute",
        type = req$REQUEST_METHOD,
        path = req$PATH_INFO,
        value = value
      ))
      # Must return the `value` since we took one in
      value
    }) %>%
    pr_hook("postserialize", function(req, value) {
      # Print stage information
      str(list(
        stage = "postserialize",
        type = req$REQUEST_METHOD,
        path = req$PATH_INFO,
        value = value
      ))
      # Must return the `value` since we took one in
      value
    })
}
```

If we were to execute a `GET` request on `/stage_debug`

``` r
#* @get /stage_debug
function(req, res) {
  return(42)
}
```

, we would expect to see output like:

    List of 4
     $ stage: chr "postroute"
     $ type : chr "GET"
     $ path : chr "/stage_debug"
     $ value: num 42
    List of 4
     $ stage: chr "postserialize"
     $ type : chr "GET"
     $ path : chr "/stage_debug"
     $ value:List of 3
      ..$ status : int 200
      ..$ headers:List of 1
      .. ..$ Content-Type: chr "application/json"
      ..$ body   : 'json' chr "[42]"

This output shows that the route `/stage_debug` calculated the value
`42` and that the value was serialized using json. We should expect to
see that the received response has a status of `200` and the body
containing JSON matching `[42]`.

### Interactive Debugging

Print debugging is an obvious starting point, but most developers
eventually wish for something more powerful. In R, this capacity is
built in to the [`browser()`](https://rdrr.io/r/base/browser.html)
function. If you’re unfamiliar,
[`browser()`](https://rdrr.io/r/base/browser.html) pauses the execution
of some function and gives you an interactive session in which you can
inspect the current value of internal variables or even proceed through
your function one statement at a time.

You can leverage [`browser()`](https://rdrr.io/r/base/browser.html) when
developing your APIs locally by adding a
[`browser()`](https://rdrr.io/r/base/browser.html) call in one of your
filters or endpoints and then visiting your API in a client. This offers
a powerful technique to use when you want to inspect multiple different
variables or interact with the current state of things inside of your
function. This is also a good way to get your hands dirty with Plumber
and get better acquainted with how things behave at a low level.
Consider the following API endpoint:

``` r
#* @get /
function(req, res){
  browser()

  list(a=123)
}
```

If you run this API locally and then visit the API in a web browser,
you’ll see your R session switch into debug mode when the request
arrives, allowing you to look at the objects contained inside your `req`
and `res` objects.

## Port Range

You can use \[httpuv::randomPort()\] to define a range of port for
Plumber to pick from when running an API.

``` r
# plumber.R
options("plumber.port" = httpuv::randomPort(min = 4000, max = 7000, n = 100))

### define the rest of your plumber router...
```

or more programmatically

``` r
pr() %>%
  pr_run(port = httpuv::randomPort(min = 4000, max = 7000, n = 100))
```
