# Package Plumber Router

Package Plumber Router

Package Plumber Router

## Details

Routers are the core request handler in plumber. A router is responsible
for taking an incoming request, submitting it through the appropriate
filters and eventually to a corresponding endpoint, if one is found.

See the [Programmatic
Usage](https://www.rplumber.io/articles/programmatic-usage.html) article
for additional details on the methods available on this object.

## See also

[`pr()`](https://www.rplumber.io/reference/pr.md),
[`pr_run()`](https://www.rplumber.io/reference/pr_run.md),
[`pr_get()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_post()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_mount()`](https://www.rplumber.io/reference/pr_mount.md),
[`pr_hook()`](https://www.rplumber.io/reference/pr_hook.md),
[`pr_hooks()`](https://www.rplumber.io/reference/pr_hook.md),
[`pr_cookie()`](https://www.rplumber.io/reference/pr_cookie.md),
[`pr_filter()`](https://www.rplumber.io/reference/pr_filter.md),
[`pr_set_api_spec()`](https://www.rplumber.io/reference/pr_set_api_spec.md),
[`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md),
[`pr_set_serializer()`](https://www.rplumber.io/reference/pr_set_serializer.md),
[`pr_set_parsers()`](https://www.rplumber.io/reference/pr_set_parsers.md),
[`pr_set_404()`](https://www.rplumber.io/reference/pr_set_404.md),
[`pr_set_error()`](https://www.rplumber.io/reference/pr_set_error.md),
[`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md),
[`pr_set_docs_callback()`](https://www.rplumber.io/reference/pr_set_docs_callback.md)

## Super class

[`plumber::Hookable`](https://www.rplumber.io/reference/Hookable.md) -\>
`Plumber`

## Public fields

- `flags`:

  For internal use only

## Active bindings

- `endpoints`:

  Plumber router endpoints read-only

- `filters`:

  Plumber router filters read-only

- `mounts`:

  Plumber router mounts read-only

- `environment`:

  Plumber router environment read-only

- `routes`:

  Plumber router routes read-only

## Methods

### Public methods

- [`Plumber$new()`](#method-Plumber-new)

- [`Plumber$run()`](#method-Plumber-run)

- [`Plumber$mount()`](#method-Plumber-mount)

- [`Plumber$unmount()`](#method-Plumber-unmount)

- [`Plumber$registerHook()`](#method-Plumber-registerHook)

- [`Plumber$handle()`](#method-Plumber-handle)

- [`Plumber$removeHandle()`](#method-Plumber-removeHandle)

- [`Plumber$print()`](#method-Plumber-print)

- [`Plumber$serve()`](#method-Plumber-serve)

- [`Plumber$route()`](#method-Plumber-route)

- [`Plumber$call()`](#method-Plumber-call)

- [`Plumber$onHeaders()`](#method-Plumber-onHeaders)

- [`Plumber$onWSOpen()`](#method-Plumber-onWSOpen)

- [`Plumber$setSerializer()`](#method-Plumber-setSerializer)

- [`Plumber$setParsers()`](#method-Plumber-setParsers)

- [`Plumber$set404Handler()`](#method-Plumber-set404Handler)

- [`Plumber$setErrorHandler()`](#method-Plumber-setErrorHandler)

- [`Plumber$setDocs()`](#method-Plumber-setDocs)

- [`Plumber$setDocsCallback()`](#method-Plumber-setDocsCallback)

- [`Plumber$setDebug()`](#method-Plumber-setDebug)

- [`Plumber$getDebug()`](#method-Plumber-getDebug)

- [`Plumber$filter()`](#method-Plumber-filter)

- [`Plumber$setApiSpec()`](#method-Plumber-setApiSpec)

- [`Plumber$getApiSpec()`](#method-Plumber-getApiSpec)

- [`Plumber$addEndpoint()`](#method-Plumber-addEndpoint)

- [`Plumber$addAssets()`](#method-Plumber-addAssets)

- [`Plumber$addFilter()`](#method-Plumber-addFilter)

- [`Plumber$addGlobalProcessor()`](#method-Plumber-addGlobalProcessor)

- [`Plumber$openAPIFile()`](#method-Plumber-openAPIFile)

- [`Plumber$swaggerFile()`](#method-Plumber-swaggerFile)

- [`Plumber$clone()`](#method-Plumber-clone)

Inherited methods

- [`plumber::Hookable$registerHooks()`](https://www.rplumber.io/reference/Hookable.html#method-registerHooks)

------------------------------------------------------------------------

### Method [`new()`](https://rdrr.io/r/methods/new.html)

Create a new `Plumber` router

See also [`plumb()`](https://www.rplumber.io/reference/plumb.md),
[`pr()`](https://www.rplumber.io/reference/pr.md)

#### Usage

    Plumber$new(file = NULL, filters = defaultPlumberFilters, envir)

#### Arguments

- `file`:

  path to file to plumb

- `filters`:

  a list of Plumber filters

- `envir`:

  an environment to be used as the enclosure for the routers execution

#### Returns

A new `Plumber` router

------------------------------------------------------------------------

### Method `run()`

Start a server using `Plumber` object.

See also: [`pr_run()`](https://www.rplumber.io/reference/pr_run.md)

#### Usage

    Plumber$run(
      host = "127.0.0.1",
      port = get_option_or_env("plumber.port", NULL),
      swagger = deprecated(),
      debug = missing_arg(),
      swaggerCallback = missing_arg(),
      ...,
      docs = missing_arg(),
      quiet = FALSE
    )

#### Arguments

- `host`:

  a string that is a valid IPv4 or IPv6 address that is owned by this
  server, which the application will listen on. "0.0.0.0" represents all
  IPv4 addresses and "::/0" represents all IPv6 addresses.

- `port`:

  a number or integer that indicates the server port that should be
  listened on. Note that on most Unix-like systems including Linux and
  Mac OS X, port numbers smaller than 1025 require root privileges.

  This value does not need to be explicitly assigned. To explicitly set
  it, see
  [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md).

- `swagger`:

  Deprecated. Please use `docs` instead. See `$setDocs(docs)` or
  `$setApiSpec()` for more customization.

- `debug`:

  If `TRUE`, it will provide more insight into your API errors. Using
  this value will only last for the duration of the run. If a
  `$setDebug()` has not been called, `debug` will default to `FALSE` at
  `$run()` time. See `$setDebug()` for more details.

- `swaggerCallback`:

  An optional single-argument function that is called back with the URL
  to an OpenAPI user interface when one becomes ready. If missing,
  defaults to information previously set with `$setDocsCallback()`. This
  value will only be used while running the router.

- `...`:

  Should be empty.

- `docs`:

  Visual documentation value to use while running the API. This value
  will only be used while running the router. If missing, defaults to
  information previously set with `setDocs()`. For more customization,
  see `$setDocs()` or
  [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md)
  for examples.

- `quiet`:

  If `TRUE`, don't print routine startup messages.

------------------------------------------------------------------------

### Method `mount()`

Mount a Plumber router

Plumber routers can be “nested” by mounting one into another using the
`mount()` method. This allows you to compartmentalize your API by paths
which is a great technique for decomposing large APIs into smaller
files.

See also: [`pr_mount()`](https://www.rplumber.io/reference/pr_mount.md)

#### Usage

    Plumber$mount(path, router)

#### Arguments

- `path`:

  a character string. Where to mount router.

- `router`:

  a Plumber router. Router to be mounted.

#### Examples

    \dontrun{
    root <- pr()

    users <- Plumber$new("users.R")
    root$mount("/users", users)

    products <- Plumber$new("products.R")
    root$mount("/products", products)
    }

------------------------------------------------------------------------

### Method `unmount()`

Unmount a Plumber router

#### Usage

    Plumber$unmount(path)

#### Arguments

- `path`:

  a character string. Where to unmount router.

------------------------------------------------------------------------

### Method `registerHook()`

Register a hook

Plumber routers support the notion of "hooks" that can be registered to
execute some code at a particular point in the lifecycle of a request.
Plumber routers currently support four hooks:

1.  `preroute(data, req, res)`

2.  `postroute(data, req, res, value)`

3.  `preserialize(data, req, res, value)`

4.  `postserialize(data, req, res, value)`

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

You can add hooks using the `registerHook` method, or you can add
multiple hooks at once using the `registerHooks` method which takes a
name list in which the names are the names of the hooks, and the values
are the handlers themselves.

See also: [`pr_hook()`](https://www.rplumber.io/reference/pr_hook.md),
[`pr_hooks()`](https://www.rplumber.io/reference/pr_hook.md)

#### Usage

    Plumber$registerHook(
      stage = c("preroute", "postroute", "preserialize", "postserialize", "exit"),
      handler
    )

#### Arguments

- `stage`:

  a character string. Point in the lifecycle of a request.

- `handler`:

  a hook function.

#### Examples

    \dontrun{
    pr <- pr()
    pr$registerHook("preroute", function(req){
      cat("Routing a request for", req$PATH_INFO, "...\n")
    })
    pr$registerHooks(list(
      preserialize=function(req, value){
        print("About to serialize this value:")
        print(value)

        # Must return the value since we took one in. Here we're not choosing
        # to mutate it, but we could.
        value
      },
      postserialize=function(res){
        print("We serialized the value as:")
        print(res$body)
      }
    ))

    pr$handle("GET", "/", function(){ 123 })
    }

------------------------------------------------------------------------

### Method `handle()`

Define endpoints

The “handler” functions that you define in these handle calls are
identical to the code you would have defined in your plumber.R file if
you were using annotations to define your API. The handle() method takes
additional arguments that allow you to control nuanced behavior of the
endpoint like which filter it might preempt or which serializer it
should use.

See also:
[`pr_handle()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_get()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_post()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_put()`](https://www.rplumber.io/reference/pr_handle.md),
[`pr_delete()`](https://www.rplumber.io/reference/pr_handle.md)

#### Usage

    Plumber$handle(
      methods,
      path,
      handler,
      preempt,
      serializer,
      parsers,
      endpoint,
      ...
    )

#### Arguments

- `methods`:

  a character string. http method.

- `path`:

  a character string. Api endpoints

- `handler`:

  a handler function.

- `preempt`:

  a preempt function.

- `serializer`:

  a serializer function.

- `parsers`:

  a named list of parsers.

- `endpoint`:

  a `PlumberEndpoint` object.

- `...`:

  additional arguments for
  [PlumberEndpoint](https://www.rplumber.io/reference/PlumberEndpoint.md)
  `new` method (namely `lines`, `params`, `comments`, `responses` and
  `tags`. Excludes `envir`).

#### Examples

    \dontrun{
    pr <- pr()
    pr$handle("GET", "/", function(){
      "<html><h1>Programmatic Plumber!</h1></html>"
    }, serializer=plumber::serializer_html())
    }

------------------------------------------------------------------------

### Method `removeHandle()`

Remove endpoints

#### Usage

    Plumber$removeHandle(methods, path, preempt = NULL)

#### Arguments

- `methods`:

  a character string. http method.

- `path`:

  a character string. Api endpoints

- `preempt`:

  a preempt function.

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Print representation of plumber router.

#### Usage

    Plumber$print(prefix = "", topLevel = TRUE, ...)

#### Arguments

- `prefix`:

  a character string. Prefix to append to representation.

- `topLevel`:

  a logical value. When method executed on top level router, set to
  `TRUE`.

- `...`:

  additional arguments for recursive calls

#### Returns

A terminal friendly representation of a plumber router.

------------------------------------------------------------------------

### Method `serve()`

Serve a request

#### Usage

    Plumber$serve(req, res)

#### Arguments

- `req`:

  request object

- `res`:

  response object

------------------------------------------------------------------------

### Method `route()`

Route a request

#### Usage

    Plumber$route(req, res)

#### Arguments

- `req`:

  request object

- `res`:

  response object

------------------------------------------------------------------------

### Method [`call()`](https://rdrr.io/r/base/call.html)

httpuv interface call function. (Required for httpuv)

#### Usage

    Plumber$call(req)

#### Arguments

- `req`:

  request object

------------------------------------------------------------------------

### Method `onHeaders()`

httpuv interface onHeaders function. (Required for httpuv)

#### Usage

    Plumber$onHeaders(req)

#### Arguments

- `req`:

  request object

------------------------------------------------------------------------

### Method `onWSOpen()`

httpuv interface onWSOpen function. (Required for httpuv)

#### Usage

    Plumber$onWSOpen(ws)

#### Arguments

- `ws`:

  WebSocket object

------------------------------------------------------------------------

### Method `setSerializer()`

Sets the default serializer of the router.

See also:
[`pr_set_serializer()`](https://www.rplumber.io/reference/pr_set_serializer.md)

#### Usage

    Plumber$setSerializer(serializer)

#### Arguments

- `serializer`:

  a serializer function

#### Examples

    \dontrun{
    pr <- pr()
    pr$setSerializer(serializer_unboxed_json())
    }

------------------------------------------------------------------------

### Method `setParsers()`

Sets the default parsers of the router. Initialized to
`c("json", "form", "text", "octet", "multi")`

#### Usage

    Plumber$setParsers(parsers)

#### Arguments

- `parsers`:

  Can be one of:

  - A `NULL` value

  - A character vector of parser names

  - A named [`list()`](https://rdrr.io/r/base/list.html) whose keys are
    parser names names and values are arguments to be applied with
    [`do.call()`](https://rdrr.io/r/base/do.call.html)

  - A `TRUE` value, which will default to combining all parsers. This is
    great for seeing what is possible, but not great for security
    purposes

  If the parser name `"all"` is found in any character value or list
  name, all remaining parsers will be added. When using a list, parser
  information already defined will maintain their existing argument
  values. All remaining parsers will use their default arguments.

  Example:

      # provide a character string
      parsers = "json"

      # provide a named list with no arguments
      parsers = list(json = list())

      # provide a named list with arguments; include `rds`
      parsers = list(json = list(simplifyVector = FALSE), rds = list())

      # default plumber parsers
      parsers = c("json", "form", "text", "octet", "multi")

------------------------------------------------------------------------

### Method `set404Handler()`

Sets the handler that gets called if an incoming request can’t be served
by any filter, endpoint, or sub-router.

See also:
[`pr_set_404()`](https://www.rplumber.io/reference/pr_set_404.md)

#### Usage

    Plumber$set404Handler(fun)

#### Arguments

- `fun`:

  a handler function.

#### Examples

    \dontrun{
    pr <- pr()
    pr$set404Handler(function(req, res) {cat(req$PATH_INFO)})
    }

------------------------------------------------------------------------

### Method `setErrorHandler()`

Sets the error handler which gets invoked if any filter or endpoint
generates an error.

See also:
[`pr_set_404()`](https://www.rplumber.io/reference/pr_set_404.md)

#### Usage

    Plumber$setErrorHandler(fun)

#### Arguments

- `fun`:

  a handler function.

#### Examples

    \dontrun{
    pr <- pr()
    pr$setErrorHandler(function(req, res, err) {
      message("Found error: ")
      str(err)
    })
    }

------------------------------------------------------------------------

### Method `setDocs()`

Set visual documentation to use for API

See also:
[`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md),
[`register_docs()`](https://www.rplumber.io/reference/register_docs.md),
[`registered_docs()`](https://www.rplumber.io/reference/register_docs.md)

#### Usage

    Plumber$setDocs(docs = get_option_or_env("plumber.docs", TRUE), ...)

#### Arguments

- `docs`:

  a character value or a logical value. See
  [`pr_set_docs()`](https://www.rplumber.io/reference/pr_set_docs.md)
  for examples. If using
  [`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md),
  the value must be set before initializing your Plumber router.

- `...`:

  Arguments for the visual documentation. See each visual documentation
  package for further details.

------------------------------------------------------------------------

### Method `setDocsCallback()`

Set a callback to notify where the API's visual documentation is
located.

When set, it will be called with a character string corresponding to the
API docs url. This allows RStudio to locate visual documentation.

If using
[`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md),
the value must be set before initializing your Plumber router.

See also:
[`pr_set_docs_callback()`](https://www.rplumber.io/reference/pr_set_docs_callback.md)

#### Usage

    Plumber$setDocsCallback(
      callback = get_option_or_env("plumber.docs.callback", NULL)
    )

#### Arguments

- `callback`:

  a callback function for taking action on the docs url. (Also accepts
  `NULL` values to disable the `callback`.)

------------------------------------------------------------------------

### Method `setDebug()`

Set debug value to include error messages.

See also: `$getDebug()` and
[`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md)

#### Usage

    Plumber$setDebug(debug = FALSE)

#### Arguments

- `debug`:

  `TRUE` provides more insight into your API errors.

------------------------------------------------------------------------

### Method `getDebug()`

Retrieve the `debug` value. If it has never been set, it will return
`FALSE`.

See also: `$getDebug()` and
[`pr_set_debug()`](https://www.rplumber.io/reference/pr_set_debug.md)

#### Usage

    Plumber$getDebug()

------------------------------------------------------------------------

### Method [`filter()`](https://rdrr.io/r/stats/filter.html)

Add a filter to plumber router

See also:
[`pr_filter()`](https://www.rplumber.io/reference/pr_filter.md)

#### Usage

    Plumber$filter(name, expr, serializer)

#### Arguments

- `name`:

  a character string. Name of filter

- `expr`:

  an expr that resolve to a filter function or a filter function

- `serializer`:

  a serializer function

------------------------------------------------------------------------

### Method `setApiSpec()`

Allows to modify router autogenerated OpenAPI Specification

Note, the returned value will be sent through
[`serializer_unboxed_json()`](https://www.rplumber.io/reference/serializers.md)
which will turn all length 1 vectors into atomic values. To force a
vector to serialize to an array of size 1, be sure to call
[`as.list()`](https://rdrr.io/r/base/list.html) on your value.
[`list()`](https://rdrr.io/r/base/list.html) objects are always
serialized to an array value.

See also:
[`pr_set_api_spec()`](https://www.rplumber.io/reference/pr_set_api_spec.md)

#### Usage

    Plumber$setApiSpec(api = NULL)

#### Arguments

- `api`:

  This can be

  - an OpenAPI Specification formatted list object

  - a function that accepts the OpenAPI Specification autogenerated by
    `plumber` and returns a OpenAPI Specification formatted list object.

  - a path to an OpenAPI Specification

  The value returned will not be validated for OAS compatibility.

------------------------------------------------------------------------

### Method `getApiSpec()`

Retrieve OpenAPI file

#### Usage

    Plumber$getApiSpec()

------------------------------------------------------------------------

### Method `addEndpoint()`

addEndpoint has been deprecated in v0.4.0 and will be removed in a
coming release. Please use `handle()` instead.

#### Usage

    Plumber$addEndpoint(
      verbs,
      path,
      expr,
      serializer,
      processors,
      preempt = NULL,
      params = NULL,
      comments
    )

#### Arguments

- `verbs`:

  verbs

- `path`:

  path

- `expr`:

  expr

- `serializer`:

  serializer

- `processors`:

  processors

- `preempt`:

  preempt

- `params`:

  params

- `comments`:

  comments

------------------------------------------------------------------------

### Method `addAssets()`

addAssets has been deprecated in v0.4.0 and will be removed in a coming
release. Please use `mount` and `PlumberStatic$new()` instead.

#### Usage

    Plumber$addAssets(dir, path = "/public", options = list())

#### Arguments

- `dir`:

  dir

- `path`:

  path

- `options`:

  options

------------------------------------------------------------------------

### Method `addFilter()`

`$addFilter()` has been deprecated in v0.4.0 and will be removed in a
coming release. Please use `$filter()` instead.

#### Usage

    Plumber$addFilter(name, expr, serializer, processors)

#### Arguments

- `name`:

  name

- `expr`:

  expr

- `serializer`:

  serializer

- `processors`:

  processors

------------------------------------------------------------------------

### Method `addGlobalProcessor()`

`$addGlobalProcessor()` has been deprecated in v0.4.0 and will be
removed in a coming release. Please use `$registerHook`(s) instead.

#### Usage

    Plumber$addGlobalProcessor(proc)

#### Arguments

- `proc`:

  proc

------------------------------------------------------------------------

### Method `openAPIFile()`

Deprecated. Retrieve OpenAPI file

#### Usage

    Plumber$openAPIFile()

------------------------------------------------------------------------

### Method `swaggerFile()`

Deprecated. Retrieve OpenAPI file

#### Usage

    Plumber$swaggerFile()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    Plumber$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r

## ------------------------------------------------
## Method `Plumber$mount`
## ------------------------------------------------

if (FALSE) { # \dontrun{
root <- pr()

users <- Plumber$new("users.R")
root$mount("/users", users)

products <- Plumber$new("products.R")
root$mount("/products", products)
} # }

## ------------------------------------------------
## Method `Plumber$registerHook`
## ------------------------------------------------

if (FALSE) { # \dontrun{
pr <- pr()
pr$registerHook("preroute", function(req){
  cat("Routing a request for", req$PATH_INFO, "...\n")
})
pr$registerHooks(list(
  preserialize=function(req, value){
    print("About to serialize this value:")
    print(value)

    # Must return the value since we took one in. Here we're not choosing
    # to mutate it, but we could.
    value
  },
  postserialize=function(res){
    print("We serialized the value as:")
    print(res$body)
  }
))

pr$handle("GET", "/", function(){ 123 })
} # }

## ------------------------------------------------
## Method `Plumber$handle`
## ------------------------------------------------

if (FALSE) { # \dontrun{
pr <- pr()
pr$handle("GET", "/", function(){
  "<html><h1>Programmatic Plumber!</h1></html>"
}, serializer=plumber::serializer_html())
} # }

## ------------------------------------------------
## Method `Plumber$setSerializer`
## ------------------------------------------------

if (FALSE) { # \dontrun{
pr <- pr()
pr$setSerializer(serializer_unboxed_json())
} # }

## ------------------------------------------------
## Method `Plumber$set404Handler`
## ------------------------------------------------

if (FALSE) { # \dontrun{
pr <- pr()
pr$set404Handler(function(req, res) {cat(req$PATH_INFO)})
} # }

## ------------------------------------------------
## Method `Plumber$setErrorHandler`
## ------------------------------------------------

if (FALSE) { # \dontrun{
pr <- pr()
pr$setErrorHandler(function(req, res, err) {
  message("Found error: ")
  str(err)
})
} # }
```
