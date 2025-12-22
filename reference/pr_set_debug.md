# Set debug value to include error messages of routes cause an error

By default, error messages from your plumber routes are hidden, but can
be turned on by setting the debug value to `TRUE` using this setter.

## Usage

``` r
pr_set_debug(pr, debug = FALSE)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- debug:

  `TRUE` provides more insight into your API errors.

## Value

The Plumber router with the new debug setting.

## Examples

``` r
if (FALSE) { # \dontrun{
# Will contain the original error message
pr() %>%
  pr_set_debug(TRUE) %>%
  pr_get("/boom", function() stop("boom")) %>%
  pr_run()

# Will NOT contain an error message
pr() %>%
  pr_set_debug(FALSE) %>%
  pr_get("/boom", function() stop("boom")) %>%
  pr_run()
} # }

# Setting within a plumber file
#* @plumber
function(pr) {
  pr %>%
    pr_set_debug(TRUE)
}
#> function (pr) 
#> {
#>     pr %>% pr_set_debug(TRUE)
#> }
#> <environment: 0x55d900a493e8>
```
