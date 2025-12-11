# Set the `callback` to tell where the API visual documentation is located

When set, it will be called with a character string corresponding to the
API visual documentation url. This allows RStudio to locate visual
documentation.

## Usage

``` r
pr_set_docs_callback(
  pr,
  callback = get_option_or_env("plumber.docs.callback", NULL)
)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- callback:

  a callback function for taking action on the docs url.

## Value

The Plumber router with the new docs callback setting.

## Details

If using
[`options_plumber()`](https://www.rplumber.io/reference/options_plumber.md),
the value must be set before initializing your Plumber router.

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_set_docs_callback(function(url) { message("API location: ", url) }) %>%
  pr_get("/plus/<a:int>/<b:int>", function(a, b) { a + b }) %>%
  pr_run()
} # }
```
