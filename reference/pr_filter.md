# Add a filter to Plumber router

Filters can be used to modify an incoming request, return an error, or
return a response prior to the request reaching an endpoint.

## Usage

``` r
pr_filter(pr, name, expr, serializer)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- name:

  A character string. Name of filter

- expr:

  An expr that resolve to a filter function or a filter function

- serializer:

  A serializer function

## Value

The Plumber router with the defined filter added

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_filter("foo", function(req, res) {
    print("This is filter foo")
    forward()
  }) %>%
  pr_get("/hi", function() "Hello") %>%
  pr_run()
} # }
```
