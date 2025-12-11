# Request character set

Request character set

## Usage

``` r
get_character_set(content_type = NULL)
```

## Arguments

- content_type:

  Request Content-Type header

## Value

Default to `UTF-8`. Otherwise return `charset` defined in request
header.
