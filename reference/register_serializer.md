# Register a Serializer

A serializer is responsible for translating a generated R value into
output that a remote user can understand. For instance, the
`serializer_json` serializes R objects into JSON before returning them
to the user. The list of available serializers in plumber is global.

## Usage

``` r
register_serializer(name, serializer, verbose = TRUE)

registered_serializers()
```

## Arguments

- name:

  The name of the serializer (character string)

- serializer:

  The serializer function to be added. This function should accept
  arguments that can be supplied when
  [`plumb()`](https://www.rplumber.io/reference/plumb.md)ing a file.
  This function should return a function that accepts four arguments:
  `value`, `req`, `res`, and `errorHandler`. See
  `print(serializer_json)` for an example.

- verbose:

  Logical value which determines if a message should be printed when
  overwriting serializers

## Details

There are three main building-block serializers:

- `serializer_headers`: the base building-block serializer that is
  required to have
  [`as_attachment()`](https://www.rplumber.io/reference/as_attachment.md)
  work

- [`serializer_content_type()`](https://www.rplumber.io/reference/serializers.md):
  for setting the content type. (Calls
  [`serializer_headers()`](https://www.rplumber.io/reference/serializers.md))

- [`serializer_device()`](https://www.rplumber.io/reference/serializers.md):
  add endpoint hooks to turn a graphics device on and off in addition to
  setting the content type. (Uses
  [`serializer_content_type()`](https://www.rplumber.io/reference/serializers.md))

## Functions

- `register_serializer()`: Register a serializer with a name

- `registered_serializers()`: Return a list of all registered
  serializers

## Examples

``` r
# `serializer_json()` calls `serializer_content_type()` and supplies a serialization function
print(serializer_json)
#> function (..., type = "application/json") 
#> {
#>     serializer_content_type(type, function(val) {
#>         toJSON(val, ...)
#>     })
#> }
#> <bytecode: 0x559472b43920>
#> <environment: namespace:plumber>
# serializer_content_type() calls `serializer_headers()` and supplies a serialization function
print(serializer_content_type)
#> function (type, serialize_fn = identity) 
#> {
#>     if (missing(type)) {
#>         stop("You must provide the custom content type to the serializer_content_type")
#>     }
#>     stopifnot(length(type) == 1)
#>     stopifnot(is.character(type))
#>     stopifnot(nchar(type) > 0)
#>     serializer_headers(list(`Content-Type` = type), serialize_fn)
#> }
#> <bytecode: 0x559472b320f8>
#> <environment: namespace:plumber>
```
