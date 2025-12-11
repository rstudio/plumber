# Register a hook

Plumber routers support the notion of "hooks" that can be registered to
execute some code at a particular point in the lifecycle of a request.
Plumber routers currently support four hooks:

1.  `preroute(data, req, res)`

2.  `postroute(data, req, res, value)`

3.  `preserialize(data, req, res, value)`

4.  `postserialize(data, req, res, value)` In all of the above you have
    access to a disposable environment in the `data` parameter that is
    created as a temporary data store for each request. Hooks can store
    temporary data in these hooks that can be reused by other hooks
    processing this same request.

## Usage

``` r
pr_hook(pr, stage, handler)

pr_hooks(pr, handlers)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- stage:

  A character string. Point in the lifecycle of a request.

- handler:

  A hook function.

- handlers:

  A named list of hook handlers

## Value

A Plumber router with the defined hook(s) added

## Details

One feature when defining hooks in Plumber routers is the ability to
modify the returned value. The convention for such hooks is: any
function that accepts a parameter named `value` is expected to return
the new value. This could be an unmodified version of the value that was
passed in, or it could be a mutated value. But in either case, if your
hook accepts a parameter named `value`, whatever your hook returns will
be used as the new value for the response.

You can add hooks using the `pr_hook`, or you can add multiple hooks at
once using `pr_hooks`, which takes a named list in which the names are
the names of the hooks, and the values are the handlers themselves.

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_hook("preroute", function(req){
    cat("Routing a request for", req$PATH_INFO, "...\n")
  }) %>%
  pr_hooks(list(
    preserialize = function(req, value){
      print("About to serialize this value:")
      print(value)

      # Must return the value since we took one in. Here we're not choosing
      # to mutate it, but we could.
      value
    },
    postserialize = function(res){
      print("We serialized the value as:")
      print(res$body)
    }
  )) %>%
  pr_handle("GET", "/", function(){ 123 }) %>%
  pr_run()
} # }
```
