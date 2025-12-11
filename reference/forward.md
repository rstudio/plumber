# Forward Request to The Next Handler

This function is used when a filter is done processing a request and
wishes to pass control off to the next handler in the chain. If this is
not called by a filter, the assumption is that the filter fully handled
the request itself and no other filters or endpoints should be evaluated
for this request. `forward()` cannot be used within handlers to trigger
the next matching handler in the router. It only has relevance for
filters.

## Usage

``` r
forward()
```

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_filter("foo", function(req, res) {
    print("This is filter foo")
    forward()
  }) %>%
  pr_run()
} # }
```
