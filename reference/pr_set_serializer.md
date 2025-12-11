# Set the default serializer of the router

By default, Plumber serializes responses to JSON. This function updates
the default serializer to the function supplied via `serializer`

## Usage

``` r
pr_set_serializer(pr, serializer)
```

## Arguments

- pr:

  A Plumber API. Note: The supplied Plumber API object will also be
  updated in place as well as returned by the function.

- serializer:

  A serializer function

## Value

The Plumber router with the new default serializer
