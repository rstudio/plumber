# Set the handler that is called when the incoming request can't be served

This function allows a custom error message to be returned when a
request cannot be served by an existing endpoint or filter.

## Usage

``` r
pr_set_404(pr, fun)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- fun:

  A handler function

## Value

The Plumber router with a modified 404 handler

## Examples

``` r
if (FALSE) { # \dontrun{
handler_404 <- function(req, res) {
  res$status <- 404
  res$body <- "Oops"
}

pr() %>%
  pr_get("/hi", function() "Hello") %>%
  pr_set_404(handler_404) %>%
  pr_run()
} # }
```
