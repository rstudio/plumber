# Add handler to Plumber router

This collection of functions creates handlers for a Plumber router.

## Usage

``` r
pr_handle(pr, methods, path, handler, preempt, serializer, endpoint, ...)

pr_get(pr, path, handler, preempt, serializer, endpoint, ...)

pr_post(pr, path, handler, preempt, serializer, endpoint, ...)

pr_put(pr, path, handler, preempt, serializer, endpoint, ...)

pr_delete(pr, path, handler, preempt, serializer, endpoint, ...)

pr_head(pr, path, handler, preempt, serializer, endpoint, ...)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- methods:

  Character vector of HTTP methods

- path:

  The endpoint path

- handler:

  A handler function

- preempt:

  A preempt function

- serializer:

  A Plumber serializer

- endpoint:

  A `PlumberEndpoint` object

- ...:

  Additional arguments for `PlumberEndpoint`

## Value

A Plumber router with the handler added

## Details

The generic `pr_handle()` creates a handle for the given method(s).
Specific functions are implemented for the following HTTP methods:

- `GET`

- `POST`

- `PUT`

- `DELETE`

- `HEAD` Each function mutates the Plumber router in place and returns
  the updated router.

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_handle("GET", "/hi", function() "Hello World") %>%
  pr_run()

pr() %>%
  pr_handle(c("GET", "POST"), "/hi", function() "Hello World") %>%
  pr_run()

pr() %>%
  pr_get("/hi", function() "Hello World") %>%
  pr_post("/echo", function(req, res) {
    if (is.null(req$body)) return("No input")
    list(
      input = req$body
    )
  }) %>%
  pr_run()
} # }
```
