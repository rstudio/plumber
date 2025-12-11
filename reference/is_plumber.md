# Determine if Plumber object

Determine if Plumber object

## Usage

``` r
is_plumber(pr)
```

## Arguments

- pr:

  Hopefully a [`Plumber`](https://www.rplumber.io/reference/Plumber.md)
  object

## Value

Logical value if `pr` inherits from
[`Plumber`](https://www.rplumber.io/reference/Plumber.md)

## Examples

``` r
is_plumber(Plumber$new()) # TRUE
#> [1] TRUE
is_plumber(list()) # FALSE
#> [1] FALSE
```
