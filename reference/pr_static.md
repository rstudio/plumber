# Add a static route to the `plumber` object

Add a static route to the `plumber` object

## Usage

``` r
pr_static(pr, path, direc)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- path:

  The mounted path location of the static folder

- direc:

  The local folder to be served statically

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_static("/path", "./my_folder/location") %>%
  pr_run()
} # }
```
