# Create a new Plumber router

Create a new Plumber router

## Usage

``` r
pr(
  file = NULL,
  filters = defaultPlumberFilters,
  envir = new.env(parent = .GlobalEnv)
)
```

## Arguments

- file:

  Path to file to plumb

- filters:

  A list of Plumber filters

- envir:

  An environment to be used as the enclosure for the routers execution

## Value

A new [`Plumber`](https://www.rplumber.io/reference/Plumber.md) router

## Examples

``` r
if (FALSE) { # \dontrun{
pr() %>%
  pr_run()
} # }
```
