# Process a Package's Plumber API

So that packages can ship multiple plumber routers, users should store
their Plumber APIs in the `inst` subfolder `plumber`
(`./inst/plumber/API_1/plumber.R`).

## Usage

``` r
plumb_api(package = NULL, name = NULL, edit = FALSE)

available_apis(package = NULL)
```

## Arguments

- package:

  Package to inspect

- name:

  Name of the package folder to
  [`plumb()`](https://www.rplumber.io/reference/plumb.md).

- edit:

  Whether or not to open the API source code for viewing / editing

## Value

A [`Plumber`](https://www.rplumber.io/reference/Plumber.md) object. If
either `package` or `name` is null, the appropriate `available_apis()`
will be returned.

## Details

To view all available Plumber APIs across all packages, please call
`available_apis()`. A `package` value may be provided to only display a
particular package's Plumber APIs.

## Functions

- `plumb_api()`:
  [`plumb()`](https://www.rplumber.io/reference/plumb.md)s a package's
  Plumber API. Returns a
  [`Plumber`](https://www.rplumber.io/reference/Plumber.md) router
  object

- `available_apis()`: Displays all available package Plumber APIs.
  Returns a `data.frame` of `package`, `name`, and `source_directory`
  information.
