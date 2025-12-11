# Programmatic Usage

Typically, users define APIs using the “annotations,” or special
comments in their API source code. It is possible to define a Plumber
API programmatically using the same underlying R6 objects that get
created automatically when you define your API using annotations.
Interacting with Plumber at this level can offer more control and
specificity about how you want your API to behave.

## Creating and Controlling a Router

The centerpiece of Plumber is the router. Plumber routers are
responsible for coordinating incoming requests from httpuv, dispatching
the requests to the appropriate filters/endpoints, serializing the
response, and handling errors that might pop up along the way. If you’ve
been using annotations to define Plumber APIs, then you’ve already
worked with Plumber routers as that’s what the
[`plumb()`](https://www.rplumber.io/reference/plumb.md) command
produces.

To instantiate a new Plumber router programmatically, you can call
[`pr()`](https://www.rplumber.io/reference/pr.md). This will return a
blank Plumber router with no endpoints. You could call
[`pr_run()`](https://www.rplumber.io/reference/pr_run.md) on the
returned object to start the API, but it doesn’t know how to respond to
any requests so any incoming traffic would get a `404` response. We’ll
see momentarily how to add endpoints and filters onto this empty router.
Alternatively, you can pass a file that contains your annotation-based
Plumber API as the first parameter to create a router much like you do
with [`plumb()`](https://www.rplumber.io/reference/plumb.md).

Be aware that Plumber routers do come with a handful of filters
pre-configured. These built-in filters are used to do things like
process properties of the incoming request like its cookies, `POST`
body, or query string. You can specify which filters you want in your
new router by overriding the `filters` parameter when creating your new
router.

## Defining Endpoints

You can define endpoints on your router by using the
[`pr_handle()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_get()`](https://www.rplumber.io/reference/pr_handle.md), or
[`pr_post()`](https://www.rplumber.io/reference/pr_handle.md). For
instance, to define a Plumber API that response to `GET` requests on `/`
and `POST` requests on `/submit`, you could use the following code:

``` r
pr() %>%
  pr_get("/", function(req, res){
    # ...
  }) %>%
  pr_post("/submit", function(req, res){
    # ...
  })
```

The “handler” functions that you define in these calls are identical to
the code you would have defined in your `plumber.R` file if you were
using annotations to define your API.

The route methods take additional arguments that allow you to control
nuanced behavior of the endpoint like which filter it might preempt or
which serializer it should use. For instance, the following endpoint
would use Plumber’s HTML serializer.

``` r
pr() %>%
  pr_get("/", function(){
    "<html><h1>Programmatic Plumber!</h1></html>"
  }, serializer = plumber::serializer_html())
```

## Defining Filters

Use the [`filter()`](https://rdrr.io/r/stats/filter.html) method of a
Plumber router to define a new filter:

``` r
pr() %>%
  pr_filter("myFilter", function(req){
    req$filtered <- TRUE
    forward()
  }) %>%
  pr_get("/", function(req){
    paste("Am I filtered?", req$filtered)
  })
```

You can specify other options such as the serializer to use if the
filter returns a value in the
[`pr_filter()`](https://www.rplumber.io/reference/pr_filter.md) method,
as well.

## Registering Hooks on a Router

Plumber routers support the notion of “hooks” that can be registered to
execute some code at a particular point in the lifecycle of a request.
Plumber routers currently support four hooks:

- `preroute(data, req, res)`
- `postroute(data, req, res, value)`
- `preserialize(data, req, res, value)`
- `postserialize(data, req, res, value)`

In all of the above you have access to a disposable environment in the
`data` parameter that is created as a temporary data store for each
request. Hooks can store temporary data in these hooks that can be
reused by other hooks processing this same request.

One feature when defining hooks in Plumber routers is the ability to
modify the returned value. The convention for such hooks is: any
function that accepts a parameter named `value` is expected to return
the new value. This could be an unmodified version of the value that was
passed in, or it could be a mutated value. But in either case, if your
hook accepts a parameter named `value`, whatever your hook returns will
be used as the new value for the response.

You can add hooks using the `pr_hook` method, or you can add multiple
hooks at once using the `pr_hooks` method which takes a name list in
which the names are the names of the hooks, and the values are the
handlers themselves.

``` r
pr() %>%
  pr_hook("preroute", function(req) {
    cat("Routing a request for", req$PATH_INFO, "...\n")
  }) %>%
  pr_hooks(list(
    preserialize = function(req, value) {
      print("About to serialize this value:")
      print(value)

      # Must return the value since we took one in. Here we're not choosing
      # to mutate it, but we could.
      value
    },
    postserialize = function(res) {
      print("We serialized the value as:")
      print(res$body)
    }
  )) %>%
  pr_get("/", function(){ 123 })
```

Making a `GET` request to `/` will print out various information from
the three events for which we registered hooks.

## Mounting & Static File Routers

Plumber routers can be “nested” by mounting one into another using the
`mount()` method. This allows you to compartmentalize your API by paths
which is a great technique for decomposing large APIs into smaller
files.

``` r
root <- pr()

users <- pr("users.R")
products <- pr("products.R")

root %>%
  pr_mount("/users", users) %>%
  pr_mount("/products", products)

root
```

This is the same approach used for defining routers that serve a
directory of static files. Static file routers are just a special case
of Plumber routers created using
[`pr_static()`](https://www.rplumber.io/reference/pr_static.md). For
example

``` r
pr() %>%
  pr_static("/assets", "./myfiles") %>%
  pr_run()
```

This will make the files and directories stored in the `./myfiles`
directory available on your API under the `/assets/` path.

## Customizing a Router

There are a handful of useful methods to be aware of to modify the
behavior of a router. [Using hooks to alter request
processing](#router-hooks) has already been discussed, but additionally
you can modify a router’s behavior using any of the following:

- [`pr_set_serializer()`](https://www.rplumber.io/reference/pr_set_serializer.md) -
  Sets the default serializer of the router.
- [`pr_set_error()`](https://www.rplumber.io/reference/pr_set_error.md) -
  Sets the error handler which gets invoked if any filter or endpoint
  generates an error.
- [`pr_set_404()`](https://www.rplumber.io/reference/pr_set_404.md) -
  Sets the handler that gets called if an incoming request can’t be
  served by any filter, endpoint, or sub-router.
