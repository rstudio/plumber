# Set the error handler that is invoked if any filter or endpoint generates an error

Set the error handler that is invoked if any filter or endpoint
generates an error

## Usage

``` r
pr_set_error(pr, fun)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- fun:

  An error handler function. This should accept `req`, `res`, and the
  error value

## Value

The Plumber router with a modified error handler

## Examples

``` r
if (FALSE) { # \dontrun{
handler_error <- function(req, res, err){
  res$status <- 500
  list(error = "Custom Error Message")
}

pr() %>%
  pr_get("/error", function() log("a")) %>%
  pr_set_error(handler_error) %>%
  pr_run()
} # }
```
