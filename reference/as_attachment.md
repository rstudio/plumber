# Return an attachment response

This will set the appropriate fields in the `Content-Disposition` header
value. To make sure the attachment is used, be sure your serializer
eventually calls `serializer_headers`

## Usage

``` r
as_attachment(value, filename = NULL)
```

## Arguments

- value:

  Response value to be saved

- filename:

  File name to use when saving the attachment. If no `filename` is
  provided, the `value` will be treated as a regular attachment

## Value

Object with class `"plumber_attachment"`

## Examples

``` r
if (FALSE) { # \dontrun{
# plumber.R

#' @get /data
#' @serializer csv
function() {
  # will cause the file to be saved as `iris.csv`, not `data` or `data.csv`
  as_attachment(iris, "iris.csv")
}
} # }
```
