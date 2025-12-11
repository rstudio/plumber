# Process a Plumber API

Process a Plumber API

## Usage

``` r
plumb(file = NULL, dir = ".")
```

## Arguments

- file:

  The file to parse as the plumber router definition.

- dir:

  The directory containing the `plumber.R` file to parse as the plumber
  router definition. Alternatively, if an `entrypoint.R` file is found,
  it will take precedence and be responsible for returning a runnable
  router.

## Details

API routers are the core request handler in plumber. A router is
responsible for taking an incoming request, submitting it through the
appropriate filters and eventually to a corresponding endpoint, if one
is found.

See the [Programmatic
Usage](https://www.rplumber.io/articles/programmatic-usage.html) article
for additional details on the methods available on this object.
